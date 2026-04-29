//! Source domain type — a configured data source (API or scraper).

use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(transparent)]
pub struct SourceId(pub Uuid);

impl SourceId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for SourceId {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Display for SourceId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.0.fmt(f)
    }
}

/// Classification of how this source retrieves events.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum SourceType {
    TicketmasterApi,
    BandsinTownApi,
    VenueScraper,
    Manual,
    DiceFm,
}

#[derive(Debug, Clone, Serialize)]
pub struct Source {
    pub id: SourceId,
    pub name: String,
    pub source_type: SourceType,
    /// Connector-specific config stored as JSONB in the DB (e.g., venue IDs, API keys).
    pub configuration: Option<serde_json::Value>,
    pub scrape_schedule: Option<String>,
    pub last_success_at: Option<OffsetDateTime>,
    pub last_failure_at: Option<OffsetDateTime>,
    pub consecutive_failures: i32,
    pub healthy: bool,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
}
