//! Enrichment orchestrator — claims PENDING artists and runs them through enrichers.
//!
//! State machine:
//! ```text
//! PENDING → IN_PROGRESS (via claim_pending_batch SKIP LOCKED)
//!         → DONE          (at least one enricher returned a result)
//!         → FAILED        (transient error OR no result and attempts < max)
//!         → SKIPPED       (attempts >= max_attempts — no further retries)
//! ```
//!
// pattern: Imperative Shell

use std::sync::Arc;
use tokio::time::{sleep, Duration};

use crate::{
    domain::artist::{Artist, ArtistId, EnrichmentStatus},
    ports::{ArtistEnricher, ArtistRepository},
};

/// Default number of artists claimed per enrichment batch.
const DEFAULT_BATCH_SIZE: i64 = 20;
/// Default maximum enrichment attempts before marking SKIPPED.
const DEFAULT_MAX_ATTEMPTS: i32 = 3;
/// Delay between processing each artist (MusicBrainz rate limit: 1 req/sec).
const DEFAULT_RATE_LIMIT_MS: u64 = 1100;

pub struct EnrichmentOrchestrator {
    artists: Arc<dyn ArtistRepository>,
    enrichers: Vec<Arc<dyn ArtistEnricher>>,
    batch_size: i64,
    max_attempts: i32,
    rate_limit_ms: u64,
}

impl EnrichmentOrchestrator {
    pub fn new(
        artists: Arc<dyn ArtistRepository>,
        enrichers: Vec<Arc<dyn ArtistEnricher>>,
    ) -> Self {
        Self {
            artists,
            enrichers,
            batch_size: DEFAULT_BATCH_SIZE,
            max_attempts: DEFAULT_MAX_ATTEMPTS,
            rate_limit_ms: DEFAULT_RATE_LIMIT_MS,
        }
    }

    /// Claim a batch of PENDING artists and enrich them.
    /// Returns the number of artists processed.
    pub async fn enrich_batch(&self) -> anyhow::Result<usize> {
        let batch = self.artists.claim_pending_batch(self.batch_size).await?;
        let count = batch.len();
        if count == 0 {
            return Ok(0);
        }

        tracing::info!(count, "Enrichment batch claimed");

        for artist in batch {
            self.process_artist(artist).await;
            // Rate limit: wait between each artist to respect MusicBrainz's 1 req/sec limit.
            sleep(Duration::from_millis(self.rate_limit_ms)).await;
        }

        Ok(count)
    }

    /// Reset orphaned IN_PROGRESS artists to PENDING.
    /// Call at startup to recover from a crashed previous run.
    pub async fn reset_orphaned(&self) -> anyhow::Result<()> {
        let reset_count = self.artists.reset_in_progress_to_pending().await?;
        if reset_count > 0 {
            tracing::warn!(
                count = reset_count,
                "Reset orphaned IN_PROGRESS artists to PENDING (likely from a previous crash)"
            );
        }
        let retry_count = self
            .artists
            .reset_eligible_failed_to_pending(self.max_attempts)
            .await?;
        if retry_count > 0 {
            tracing::info!(
                count = retry_count,
                "Reset eligible FAILED artists to PENDING for retry"
            );
        }
        Ok(())
    }

    async fn process_artist(&self, artist: Artist) {
        // Check if this artist has exceeded max attempts (transition to SKIPPED).
        if artist.enrichment_attempts > self.max_attempts {
            self.transition(artist.id, EnrichmentStatus::Skipped, None)
                .await;
            return;
        }

        // Run all enrichers sequentially, collecting results.
        let mut any_succeeded = false;
        let mut any_threw = false;
        let mut merged = MergedResult::default();

        for enricher in &self.enrichers {
            match enricher.enrich(&artist.name).await {
                Ok(Some(result)) => {
                    tracing::debug!(
                        artist = %artist.name,
                        source = ?enricher.source(),
                        confidence = result.confidence,
                        "Enrichment result received"
                    );
                    merged.apply(result);
                    any_succeeded = true;
                }
                Ok(None) => {
                    tracing::debug!(
                        artist = %artist.name,
                        source = ?enricher.source(),
                        "No match found by enricher"
                    );
                }
                Err(e) => {
                    tracing::warn!(
                        artist = %artist.name,
                        source = ?enricher.source(),
                        error = %e,
                        "Enricher returned transient error"
                    );
                    any_threw = true;
                }
            }
        }

        // State machine transition.
        let new_status = if any_threw {
            EnrichmentStatus::Failed // Transient error — retry eligible on next batch
        } else if !any_succeeded {
            if artist.enrichment_attempts >= self.max_attempts {
                EnrichmentStatus::Skipped
            } else {
                EnrichmentStatus::Failed // Will be retried
            }
        } else {
            EnrichmentStatus::Done
        };

        self.transition(
            artist.id,
            new_status,
            if any_succeeded { Some(merged) } else { None },
        )
        .await;
    }

    async fn transition(
        &self,
        id: ArtistId,
        status: EnrichmentStatus,
        result: Option<MergedResult>,
    ) {
        // Load current artist.
        let mut artist = match self.artists.find_by_id(id).await {
            Ok(a) => a,
            Err(e) => {
                tracing::error!(error = %e, "Failed to load artist for enrichment transition");
                return;
            }
        };

        artist.enrichment_status = status;
        // Always increment attempts so the SKIPPED threshold is eventually reached.
        // This counter tracks how many enrichment cycles have been attempted, regardless
        // of outcome. Without this increment, artists can never transition to SKIPPED.
        artist.enrichment_attempts += 1;
        if let Some(r) = result {
            if let Some(name) = r.canonical_name {
                artist.canonical_name = Some(name);
            }
            if let Some(mbid) = r.musicbrainz_id {
                artist.musicbrainz_id = Some(mbid);
            }
            if let Some(spotify_id) = r.spotify_id {
                artist.spotify_id = Some(spotify_id);
            }
            if !r.mb_tags.is_empty() {
                artist.mb_tags = r.mb_tags;
            }
            if !r.spotify_genres.is_empty() {
                artist.spotify_genres = r.spotify_genres;
            }
            if let Some(img) = r.image_url {
                artist.image_url = Some(img);
            }
            artist.last_enriched_at = Some(time::OffsetDateTime::now_utc());
        }

        if let Err(e) = self.artists.save(&artist).await {
            tracing::error!(error = %e, artist = %artist.name, "Failed to save enrichment result");
        }
    }
}

/// Accumulated enrichment results from multiple enrichers.
#[derive(Default)]
struct MergedResult {
    canonical_name: Option<String>,
    musicbrainz_id: Option<String>,
    spotify_id: Option<String>,
    mb_tags: Vec<String>,
    spotify_genres: Vec<String>,
    image_url: Option<String>,
}

impl MergedResult {
    fn apply(&mut self, result: crate::domain::artist::EnrichmentResult) {
        use crate::domain::artist::EnrichmentSource;
        // Route fields based on the source field on EnrichmentResult.
        // This uses explicit source awareness rather than heuristics.
        match result.source {
            EnrichmentSource::MusicBrainz => {
                self.musicbrainz_id = self.musicbrainz_id.take().or(result.external_id);
                if !result.tags.is_empty() {
                    self.mb_tags = result.tags;
                }
            }
            EnrichmentSource::Spotify => {
                self.spotify_id = self.spotify_id.take().or(result.external_id);
                if !result.tags.is_empty() {
                    self.spotify_genres = result.tags;
                }
                self.image_url = self.image_url.take().or(result.image_url);
            }
            EnrichmentSource::Ollama => {
                // Not currently implemented; treat tags as genres.
                if !result.tags.is_empty() {
                    self.spotify_genres = result.tags;
                }
            }
        }
        self.canonical_name = self.canonical_name.take().or(result.canonical_name);
    }
}
