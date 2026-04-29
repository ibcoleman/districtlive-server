//! Artist domain type and enrichment-related types.

use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(transparent)]
pub struct ArtistId(pub Uuid);

impl ArtistId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for ArtistId {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Display for ArtistId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.0.fmt(f)
    }
}

/// Lifecycle state of artist metadata enrichment.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum EnrichmentStatus {
    Pending,
    InProgress,
    Done,
    Failed,
    Skipped,
}

/// Which external service produced an enrichment result.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum EnrichmentSource {
    MusicBrainz,
    Spotify,
    Ollama,
}

/// The result produced by a successful `ArtistEnricher::enrich` call.
#[derive(Debug, Clone)]
pub struct EnrichmentResult {
    /// Which enrichment service produced this result.
    /// Included so the orchestrator can route fields without heuristics.
    pub source: EnrichmentSource,
    /// Canonical artist name as returned by the enrichment source.
    pub canonical_name: Option<String>,
    /// Source-specific ID (MBID for MusicBrainz, Spotify ID for Spotify).
    pub external_id: Option<String>,
    /// Genre/tag strings from the enrichment source.
    pub tags: Vec<String>,
    /// URL to artist image.
    pub image_url: Option<String>,
    /// Match confidence score 0.0–1.0.
    pub confidence: f64,
}

#[derive(Debug, Clone, Serialize)]
pub struct Artist {
    pub id: ArtistId,
    pub name: String,
    pub slug: String,
    pub genres: Vec<String>,
    pub is_local: bool,
    pub spotify_url: Option<String>,
    pub bandcamp_url: Option<String>,
    pub instagram_url: Option<String>,
    pub enrichment_status: EnrichmentStatus,
    pub enrichment_attempts: i32,
    pub last_enriched_at: Option<OffsetDateTime>,
    pub musicbrainz_id: Option<String>,
    pub spotify_id: Option<String>,
    pub canonical_name: Option<String>,
    pub mb_tags: Vec<String>,
    pub spotify_genres: Vec<String>,
    pub image_url: Option<String>,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
}
