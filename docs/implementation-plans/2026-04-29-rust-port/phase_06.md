# DistrictLive Rust Port — Phase 6: Enrichment Pipeline

**Goal:** Artist enrichment runs against real external APIs, gated by `ENRICHMENT_ENABLED`. State machine transitions are correct and safe under concurrent execution.

**Architecture:** `src/adapters/enrichers/` holds the two `ArtistEnricher` adapter implementations. `src/enrichment/` holds the orchestrator and scheduler. The orchestrator claims PENDING artists with `SELECT FOR UPDATE SKIP LOCKED` (from Phase 3's `claim_pending_batch`), runs all enabled enrichers sequentially, merges results field-by-field, and transitions to DONE/FAILED/SKIPPED. A startup one-shot resets orphaned IN_PROGRESS artists to PENDING. The scheduler is gated on `ENRICHMENT_ENABLED`.

**Tech Stack:** `reqwest` 0.12 (shared client from AppState), `strsim` 0.11 (Jaro-Winkler, already added in Phase 5), `tokio::time::sleep` for rate limiting, `tokio-cron-scheduler` for scheduling

**Scope:** Phase 6 of 7 from original design

**Codebase verified:** 2026-04-29

---

## Acceptance Criteria Coverage

### rust-port.AC4: Artist enrichment pipeline
- **rust-port.AC4.1 Success:** A PENDING artist is claimed, marked IN_PROGRESS, successfully enriched via MusicBrainz, and transitioned to DONE with canonical name, MBID, and tags populated
- **rust-port.AC4.2 Success:** An artist that fails enrichment on every attempt up to `max_attempts` is marked SKIPPED
- **rust-port.AC4.3 Success:** On application startup, any IN_PROGRESS artists left from a previous crashed run are reset to PENDING
- **rust-port.AC4.4 Failure:** A transient enrichment error marks the artist FAILED (not SKIPPED), leaving it eligible for retry on the next batch
- **rust-port.AC4.5 Edge:** Spotify enricher is disabled by default; it only runs when `SPOTIFY_ENABLED=true` in the environment

---

<!-- START_SUBCOMPONENT_A (tasks 1-2) -->

<!-- START_TASK_1 -->
### Task 1: MusicBrainz enricher

**Verifies:** rust-port.AC4.1

**Files:**
- Create: `src/adapters/enrichers/mod.rs`
- Create: `src/adapters/enrichers/musicbrainz.rs`
- Modify: `src/adapters/mod.rs` — add `pub mod enrichers;`

**Step 1: Create src/adapters/enrichers/mod.rs**

```rust
pub mod musicbrainz;
pub mod spotify;
```

**Step 2: Create src/adapters/enrichers/musicbrainz.rs**

```rust
//! MusicBrainz artist enricher.
//!
//! Rate-limited to 1 request per second per MusicBrainz terms of service.
//! Uses Jaro-Winkler similarity to validate name matches.

use async_trait::async_trait;
use reqwest::Client;
use strsim::jaro_winkler;

use crate::{
    config::Config,
    domain::{
        artist::{EnrichmentResult, EnrichmentSource},
        error::EnrichmentError,
    },
    ports::ArtistEnricher,
};

/// MusicBrainz search API endpoint.
const MB_SEARCH_URL: &str = "https://musicbrainz.org/ws/2/artist/";

/// MusicBrainz server-side relevance score threshold (0–100).
/// Responses with score below this are not considered matches.
const MB_SERVER_SCORE_THRESHOLD: u32 = 80;

pub struct MusicBrainzEnricher {
    client: Client,
    confidence_threshold: f64,
    user_agent: String,
}

impl MusicBrainzEnricher {
    pub fn new(client: Client, config: &Config) -> Self {
        Self {
            client,
            confidence_threshold: config.musicbrainz_confidence_threshold,
            user_agent: format!(
                "districtlive-server/{} (https://districtlive.com)",
                env!("CARGO_PKG_VERSION")
            ),
        }
    }

    /// Parse a MusicBrainz search response JSON for a given artist name.
    /// Exposed for testing without HTTP calls.
    pub fn parse_response(
        json: &serde_json::Value,
        queried_name: &str,
        confidence_threshold: f64,
    ) -> Option<EnrichmentResult> {
        let artists = json.get("artists")?.as_array()?;
        let top = artists.first()?;

        let server_score = top.get("score")
            .and_then(|s| s.as_u64())
            .unwrap_or(0) as u32;

        if server_score < MB_SERVER_SCORE_THRESHOLD {
            return None;
        }

        let mb_name = top.get("name").and_then(|n| n.as_str())?;
        let confidence = jaro_winkler(
            &queried_name.to_lowercase(),
            &mb_name.to_lowercase(),
        );

        if confidence < confidence_threshold {
            return None;
        }

        let mbid = top.get("id").and_then(|i| i.as_str()).map(str::to_owned);
        let tags = top.get("tags")
            .and_then(|t| t.as_array())
            .map(|arr| {
                arr.iter()
                    .filter_map(|t| t.get("name").and_then(|n| n.as_str()).map(str::to_owned))
                    .collect::<Vec<_>>()
            })
            .unwrap_or_default();

        Some(EnrichmentResult {
            source: crate::domain::artist::EnrichmentSource::MusicBrainz,
            canonical_name: Some(mb_name.to_owned()),
            external_id: mbid,
            tags,
            image_url: None, // MusicBrainz does not provide images in search
            confidence,
        })
    }
}

#[async_trait]
impl ArtistEnricher for MusicBrainzEnricher {
    fn source(&self) -> EnrichmentSource {
        EnrichmentSource::MusicBrainz
    }

    async fn enrich(&self, name: &str) -> Result<Option<EnrichmentResult>, EnrichmentError> {
        let response = self.client
            .get(MB_SEARCH_URL)
            .header("User-Agent", &self.user_agent)
            .query(&[
                ("query", name),
                ("fmt", "json"),
                ("inc", "tags"),     // Include tag data in response
                ("limit", "5"),
            ])
            .send()
            .await
            .map_err(|e| EnrichmentError::Http(e))?;

        if !response.status().is_success() {
            return Err(EnrichmentError::Api(format!(
                "MusicBrainz returned status {}",
                response.status()
            )));
        }

        let json: serde_json::Value = response
            .json()
            .await
            .map_err(|e| EnrichmentError::Http(e))?;

        Ok(Self::parse_response(&json, name, self.confidence_threshold))
    }
}
```

**Commit:** `feat: MusicBrainz enricher with server score + Jaro-Winkler filtering`
<!-- END_TASK_1 -->

<!-- START_TASK_2 -->
### Task 2: Spotify enricher

**Verifies:** rust-port.AC4.5

**Files:**
- Create: `src/adapters/enrichers/spotify.rs`

```rust
//! Spotify artist enricher.
//!
//! Disabled by default (`Config.spotify_enabled = false`).
//! Uses OAuth2 client credentials flow with token caching.
//! Handles HTTP 429 rate limiting with Retry-After backoff.

use async_trait::async_trait;
use reqwest::Client;
use serde::Deserialize;
use strsim::jaro_winkler;
use std::sync::Arc;
use tokio::sync::Mutex;
use tokio::time::{sleep, Duration};

use crate::{
    config::Config,
    domain::{
        artist::{EnrichmentResult, EnrichmentSource},
        error::EnrichmentError,
    },
    ports::ArtistEnricher,
};

const SPOTIFY_TOKEN_URL: &str = "https://accounts.spotify.com/api/token";
const SPOTIFY_SEARCH_URL: &str = "https://api.spotify.com/v1/search";
const SPOTIFY_CONFIDENCE_THRESHOLD: f64 = 0.90;
const MAX_RETRIES: u32 = 3;
/// Expire cached token 60 seconds early as a safety buffer.
const TOKEN_EXPIRY_BUFFER_SECS: u64 = 60;

#[derive(Debug)]
struct CachedToken {
    access_token: String,
    /// Unix timestamp when this token expires (after applying expiry buffer).
    expires_at: u64,
}

impl CachedToken {
    fn is_valid(&self) -> bool {
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        self.expires_at > now
    }
}

pub struct SpotifyEnricher {
    client: Client,
    client_id: String,
    client_secret: String,
    confidence_threshold: f64,
    token_cache: Arc<Mutex<Option<CachedToken>>>,
}

impl SpotifyEnricher {
    pub fn new(client: Client, config: &Config) -> Option<Self> {
        // Only create enricher if Spotify is enabled and credentials are provided
        if !config.spotify_enabled {
            return None;
        }
        let client_id = config.spotify_client_id.clone()?;
        let client_secret = config.spotify_client_secret.clone()?;
        Some(Self {
            client,
            client_id,
            client_secret,
            confidence_threshold: SPOTIFY_CONFIDENCE_THRESHOLD,
            token_cache: Arc::new(Mutex::new(None)),
        })
    }

    async fn get_token(&self) -> Result<String, EnrichmentError> {
        let mut cache = self.token_cache.lock().await;
        if let Some(token) = cache.as_ref() {
            if token.is_valid() {
                return Ok(token.access_token.clone());
            }
        }

        #[derive(Deserialize)]
        struct TokenResponse {
            access_token: String,
            expires_in: u64,
        }

        let response: TokenResponse = self.client
            .post(SPOTIFY_TOKEN_URL)
            .basic_auth(&self.client_id, Some(&self.client_secret))
            .form(&[("grant_type", "client_credentials")])
            .send()
            .await
            .map_err(|e| EnrichmentError::Http(e))?
            .json()
            .await
            .map_err(|e| EnrichmentError::Http(e))?;

        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        *cache = Some(CachedToken {
            access_token: response.access_token.clone(),
            expires_at: now + response.expires_in.saturating_sub(TOKEN_EXPIRY_BUFFER_SECS),
        });

        Ok(response.access_token)
    }

    async fn search(&self, name: &str, token: &str) -> Result<serde_json::Value, EnrichmentError> {
        let mut attempts = 0;
        loop {
            let response = self.client
                .get(SPOTIFY_SEARCH_URL)
                .query(&[("q", name), ("type", "artist"), ("limit", "5")])
                .bearer_auth(token)
                .send()
                .await
                .map_err(|e| EnrichmentError::Http(e))?;

            if response.status() == reqwest::StatusCode::TOO_MANY_REQUESTS {
                attempts += 1;
                if attempts >= MAX_RETRIES {
                    return Err(EnrichmentError::RateLimited);
                }
                let retry_after = response
                    .headers()
                    .get("Retry-After")
                    .and_then(|v| v.to_str().ok())
                    .and_then(|s| s.parse::<u64>().ok())
                    .unwrap_or(1);
                tracing::warn!(retry_after, "Spotify rate limited — waiting before retry");
                sleep(Duration::from_secs(retry_after)).await;
                continue;
            }

            if !response.status().is_success() {
                return Err(EnrichmentError::Api(format!(
                    "Spotify returned status {}",
                    response.status()
                )));
            }

            return response.json().await.map_err(|e| EnrichmentError::Http(e));
        }
    }
}

#[async_trait]
impl ArtistEnricher for SpotifyEnricher {
    fn source(&self) -> EnrichmentSource {
        EnrichmentSource::Spotify
    }

    async fn enrich(&self, name: &str) -> Result<Option<EnrichmentResult>, EnrichmentError> {
        let token = self.get_token().await?;
        let json = self.search(name, &token).await?;

        let items = json.get("artists")
            .and_then(|a| a.get("items"))
            .and_then(|i| i.as_array())
            .and_then(|arr| arr.first());

        let item = match items {
            Some(i) => i,
            None => return Ok(None),
        };

        let spotify_name = item.get("name").and_then(|n| n.as_str())?;
        let confidence = jaro_winkler(
            &name.to_lowercase(),
            &spotify_name.to_lowercase(),
        );

        if confidence < self.confidence_threshold {
            return Ok(None);
        }

        let spotify_id = item.get("id").and_then(|i| i.as_str()).map(str::to_owned);
        let genres = item.get("genres")
            .and_then(|g| g.as_array())
            .map(|arr| arr.iter()
                .filter_map(|g| g.as_str().map(str::to_owned))
                .collect::<Vec<_>>())
            .unwrap_or_default();
        let image_url = item.get("images")
            .and_then(|i| i.as_array())
            .and_then(|arr| arr.first())
            .and_then(|img| img.get("url"))
            .and_then(|u| u.as_str())
            .map(str::to_owned);

        Ok(Some(EnrichmentResult {
            source: crate::domain::artist::EnrichmentSource::Spotify,
            canonical_name: Some(spotify_name.to_owned()),
            external_id: spotify_id,
            tags: genres,
            image_url,
            confidence,
        }))
    }
}
```

**Commit:** `feat: Spotify enricher with OAuth2 token caching and 429 retry`
<!-- END_TASK_2 -->

<!-- END_SUBCOMPONENT_A -->

<!-- START_SUBCOMPONENT_B (tasks 3-5) -->

<!-- START_TASK_3 -->
### Task 3: Enrichment orchestrator

**Verifies:** rust-port.AC4.1, rust-port.AC4.2, rust-port.AC4.3, rust-port.AC4.4

**Files:**
- Create: `src/enrichment/orchestrator.rs`
- Modify: `src/enrichment/mod.rs` — add `pub mod orchestrator; pub mod scheduler;`

**Update src/enrichment/mod.rs:**

```rust
//! Enrichment pipeline — orchestration and scheduling.

pub mod orchestrator;
pub mod scheduler;
```

**Create src/enrichment/orchestrator.rs:**

```rust
//! Enrichment orchestrator — claims PENDING artists and runs them through enrichers.
//!
//! State machine:
//! ```text
//! PENDING → IN_PROGRESS (via claim_pending_batch SKIP LOCKED)
//!         → DONE          (at least one enricher returned a result)
//!         → FAILED        (transient error OR no result and attempts < max)
//!         → SKIPPED       (attempts > max_attempts — no further retries)
//! ```

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
            // Rate limit: wait between each artist to respect MusicBrainz's 1 req/sec limit
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
        let retry_count = self.artists
            .reset_eligible_failed_to_pending(self.max_attempts)
            .await?;
        if retry_count > 0 {
            tracing::info!(count = retry_count, "Reset eligible FAILED artists to PENDING for retry");
        }
        Ok(())
    }

    async fn process_artist(&self, artist: Artist) {
        // Check if this artist has exceeded max attempts (transition to SKIPPED)
        if artist.enrichment_attempts > self.max_attempts {
            self.transition(artist.id, EnrichmentStatus::Skipped, None).await;
            return;
        }

        // Run all enrichers sequentially, collecting results
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

        // State machine transition
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

        self.transition(artist.id, new_status, if any_succeeded { Some(merged) } else { None }).await;
    }

    async fn transition(
        &self,
        id: ArtistId,
        status: EnrichmentStatus,
        result: Option<MergedResult>,
    ) {
        // Load current artist
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
            if let Some(name) = r.canonical_name { artist.canonical_name = Some(name); }
            if let Some(mbid) = r.musicbrainz_id { artist.musicbrainz_id = Some(mbid); }
            if let Some(spotify_id) = r.spotify_id { artist.spotify_id = Some(spotify_id); }
            if !r.mb_tags.is_empty() { artist.mb_tags = r.mb_tags; }
            if !r.spotify_genres.is_empty() { artist.spotify_genres = r.spotify_genres; }
            if let Some(img) = r.image_url { artist.image_url = Some(img); }
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
        // Route fields based on the source field added to EnrichmentResult in Phase 2.
        // This replaces the earlier UUID-length heuristic with explicit source awareness.
        match result.source {
            EnrichmentSource::MusicBrainz => {
                self.musicbrainz_id = self.musicbrainz_id.take().or(result.external_id.clone());
                if !result.tags.is_empty() { self.mb_tags = result.tags.clone(); }
            }
            EnrichmentSource::Spotify => {
                self.spotify_id = self.spotify_id.take().or(result.external_id.clone());
                if !result.tags.is_empty() { self.spotify_genres = result.tags.clone(); }
                self.image_url = self.image_url.take().or(result.image_url.clone());
            }
            EnrichmentSource::Ollama => {
                // Not currently implemented; treat tags as genres
                if !result.tags.is_empty() { self.spotify_genres = result.tags.clone(); }
            }
        }
        self.canonical_name = self.canonical_name.take().or(result.canonical_name.clone());
    }
}
```

Note: `MergedResult::apply()` routes enrichment results by source using the `source: EnrichmentSource` field on `EnrichmentResult` (added to the struct in Phase 2 Task 3). Each enricher populates this field explicitly when constructing its result — see the `source: EnrichmentSource::MusicBrainz` / `source: EnrichmentSource::Spotify` fields in the enricher implementations above.

**Commit:** `feat: enrichment orchestrator with DONE/FAILED/SKIPPED state machine`
<!-- END_TASK_3 -->

<!-- START_TASK_4 -->
### Task 4: Enrichment scheduler + startup orphan reset

**Verifies:** rust-port.AC4.3 (startup reset)

**Files:**
- Create: `src/enrichment/scheduler.rs`
- Modify: `src/main.rs` — add startup orphan reset + conditional scheduler spawn

**Create src/enrichment/scheduler.rs:**

```rust
//! Enrichment scheduler — fires enrichment batches on a cron schedule.

use std::sync::Arc;
use tokio_cron_scheduler::{Job, JobScheduler};

use crate::{config::Config, enrichment::orchestrator::EnrichmentOrchestrator};

/// Start the enrichment cron scheduler. Returns immediately; job runs in background.
///
/// No-op if `config.enrichment_enabled` is false.
pub async fn start_enrichment_scheduler(
    config: Arc<Config>,
    orchestrator: Arc<EnrichmentOrchestrator>,
) -> anyhow::Result<JobScheduler> {
    let sched = JobScheduler::new().await?;

    let orchestrator_clone = orchestrator.clone();
    let cron = config.enrichment_cron.clone();

    sched.add(Job::new_async(&cron, move |_uuid, _l| {
        let orchestrator = orchestrator_clone.clone();
        Box::pin(async move {
            match orchestrator.enrich_batch().await {
                Ok(count) => tracing::info!(count, "Enrichment batch completed"),
                Err(e) => tracing::error!(error = %e, "Enrichment batch failed"),
            }
        })
    })?).await?;

    sched.start().await?;
    tracing::info!(cron = %config.enrichment_cron, "Enrichment scheduler started");
    Ok(sched)
}
```

**Update src/main.rs — startup orphan reset + scheduler:**

After database connection and before starting the HTTP server, add:

```rust
// Startup enrichment orphan reset (runs once, regardless of ENRICHMENT_ENABLED)
// Resets IN_PROGRESS artists from any previous crashed run back to PENDING
{
    let artists = state.artists.clone();
    tokio::spawn(async move {
        let orchestrator = EnrichmentOrchestrator::new(
            artists,
            vec![], // No enrichers needed for orphan reset
        );
        if let Err(e) = orchestrator.reset_orphaned().await {
            tracing::error!(error = %e, "Startup orphan reset failed");
        }
    });
}

// Start enrichment scheduler if ENRICHMENT_ENABLED=true
if config.enrichment_enabled {
    let mut enrichers: Vec<Arc<dyn ArtistEnricher>> = vec![
        Arc::new(MusicBrainzEnricher::new(http_client.clone(), &config)),
    ];
    if let Some(spotify) = SpotifyEnricher::new(http_client.clone(), &config) {
        enrichers.push(Arc::new(spotify));
    }

    let orchestrator = Arc::new(EnrichmentOrchestrator::new(
        state.artists.clone(),
        enrichers,
    ));

    tokio::spawn(async move {
        if let Err(e) = start_enrichment_scheduler(config.clone(), orchestrator).await {
            tracing::error!(error = %e, "Failed to start enrichment scheduler");
        }
    });
}
```

**Commit:** `feat: enrichment scheduler + startup orphan reset`
<!-- END_TASK_4 -->

<!-- START_TASK_5 -->
### Task 5: Integration tests for enrichment state machine

**Verifies:** rust-port.AC4.1, rust-port.AC4.2, rust-port.AC4.3, rust-port.AC4.4

**Files:**
- Modify: `tests/integration_db.rs` — add enrichment state machine tests

**Add to tests/integration_db.rs:**

```rust
use districtlive_server::{
    adapters::enrichers::musicbrainz::MusicBrainzEnricher,
    domain::artist::EnrichmentStatus,
    enrichment::orchestrator::EnrichmentOrchestrator,
    ports::{ArtistRepository, EventRepository},
};
use std::sync::Arc;

// ---- AC4.3: Startup orphan reset ----

#[tokio::test]
#[ignore]
async fn startup_reset_clears_in_progress() {
    let (pool, helper) = setup().await;
    let events = PgEventRepository::new(pool.clone());
    let artists = PgArtistRepository::new(pool.clone());

    // Create an artist via event upsert
    events.upsert(test_event_cmd("test-event-orphan")).await.unwrap();

    // Claim it (marks IN_PROGRESS)
    let claimed = artists.claim_pending_batch(10).await.unwrap();
    assert!(!claimed.is_empty());

    // Simulate orphan reset (as if app crashed and restarted)
    let orchestrator = EnrichmentOrchestrator::new(
        Arc::new(PgArtistRepository::new(pool.clone())),
        vec![], // No enrichers needed
    );
    orchestrator.reset_orphaned().await.unwrap();

    // Verify artists are back to PENDING
    let all = artists.find_all(districtlive_server::domain::Pagination::default()).await.unwrap();
    let in_progress = all.items.iter()
        .filter(|a| a.enrichment_status == EnrichmentStatus::InProgress)
        .count();
    assert_eq!(in_progress, 0, "All IN_PROGRESS artists should be reset to PENDING");
}

// ---- AC4.2: SKIPPED after max_attempts ----

#[tokio::test]
#[ignore]
async fn artist_marked_skipped_after_max_attempts() {
    let (pool, helper) = setup().await;
    let events = PgEventRepository::new(pool.clone());
    let artists = PgArtistRepository::new(pool.clone());

    // Create an artist
    events.upsert(test_event_cmd("test-event-skip")).await.unwrap();
    let all = artists.find_all(districtlive_server::domain::Pagination::default()).await.unwrap();
    let artist_id = all.items[0].id;

    // A stub enricher that always returns no result (simulating no match)
    struct NullEnricher;
    #[async_trait::async_trait]
    impl ArtistEnricher for NullEnricher {
        fn source(&self) -> districtlive_server::domain::artist::EnrichmentSource {
            districtlive_server::domain::artist::EnrichmentSource::MusicBrainz
        }
        async fn enrich(&self, _name: &str) -> Result<Option<districtlive_server::domain::artist::EnrichmentResult>, districtlive_server::domain::error::EnrichmentError> {
            Ok(None) // Never matches
        }
    }

    let orchestrator = EnrichmentOrchestrator::new(
        Arc::new(PgArtistRepository::new(pool.clone())),
        vec![Arc::new(NullEnricher)],
    );

    // Run 4 batches (max_attempts = 3, so 4th run should mark SKIPPED)
    for _ in 0..4 {
        orchestrator.enrich_batch().await.unwrap();
        // Reset eligible FAILED back to PENDING for retry
        artists.reset_eligible_failed_to_pending(3).await.unwrap();
    }

    let artist = artists.find_by_id(artist_id).await.unwrap();
    assert_eq!(
        artist.enrichment_status,
        EnrichmentStatus::Skipped,
        "Artist should be SKIPPED after exceeding max_attempts"
    );
}

// ---- AC4.4: Transient error → FAILED (not SKIPPED) ----

#[tokio::test]
#[ignore]
async fn transient_error_marks_failed_not_skipped() {
    let (pool, helper) = setup().await;
    let events = PgEventRepository::new(pool.clone());
    let artists = PgArtistRepository::new(pool.clone());

    events.upsert(test_event_cmd("test-event-failed")).await.unwrap();

    struct ErrorEnricher;
    #[async_trait::async_trait]
    impl ArtistEnricher for ErrorEnricher {
        fn source(&self) -> districtlive_server::domain::artist::EnrichmentSource {
            districtlive_server::domain::artist::EnrichmentSource::MusicBrainz
        }
        async fn enrich(&self, _name: &str) -> Result<Option<districtlive_server::domain::artist::EnrichmentResult>, districtlive_server::domain::error::EnrichmentError> {
            Err(districtlive_server::domain::error::EnrichmentError::Api("transient error".to_owned()))
        }
    }

    let orchestrator = EnrichmentOrchestrator::new(
        Arc::new(PgArtistRepository::new(pool.clone())),
        vec![Arc::new(ErrorEnricher)],
    );

    orchestrator.enrich_batch().await.unwrap();

    let all = artists.find_all(districtlive_server::domain::Pagination::default()).await.unwrap();
    let artist = &all.items[0];
    assert_eq!(
        artist.enrichment_status,
        EnrichmentStatus::Failed,
        "Transient error should mark FAILED not SKIPPED"
    );
}
```

**Run tests:**

```bash
just test-integration
```

Expected: Integration tests for enrichment state machine pass.

**Commit:** `test: enrichment state machine integration tests (AC4.1-AC4.4)`
<!-- END_TASK_5 -->

<!-- END_SUBCOMPONENT_B -->

<!-- START_TASK_6 -->
### Task 6: Final Phase 6 verification

**Step 1: Run full check**

```bash
just check
```

Expected: No clippy warnings. Fix any issues:
- `dead_code` on `MergedResult` fields — suppress with `#[expect]` or ensure all fields are used
- `unused_import` — remove

**Step 2: Run tests**

```bash
just test
```

Expected: All tests pass.

**Step 3: Verify Spotify is gated by default**

Verify `SpotifyEnricher::new()` returns `None` when `Config.spotify_enabled = false`:

```rust
// In a unit test or by inspection:
let config = Config { spotify_enabled: false, ..Config::default() };
assert!(SpotifyEnricher::new(client, &config).is_none());
```

This verifies rust-port.AC4.5 without needing actual Spotify credentials.

**Step 4: Run integration tests (requires just dev on host)**

```bash
just test-integration
```

Expected: Orphan reset, SKIPPED transition, and FAILED transition tests all pass.

**Commit:** `chore: phase 6 verification — just check and just test passing`
<!-- END_TASK_6 -->
