//! IngestionRun domain type — a single execution record of the ingestion pipeline for one source.

use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::source::SourceId;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(transparent)]
pub struct IngestionRunId(pub Uuid);

impl IngestionRunId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for IngestionRunId {
    fn default() -> Self {
        Self::new()
    }
}

/// Lifecycle status of an ingestion run.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum IngestionRunStatus {
    Running,
    Success,
    Failed,
}

#[derive(Debug, Clone, Serialize)]
pub struct IngestionRun {
    pub id: IngestionRunId,
    pub source_id: SourceId,
    pub status: IngestionRunStatus,
    pub events_fetched: i32,
    pub events_created: i32,
    pub events_updated: i32,
    pub events_deduplicated: i32,
    pub error_message: Option<String>,
    pub started_at: OffsetDateTime,
    pub completed_at: Option<OffsetDateTime>,
}
