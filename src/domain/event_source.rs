//! EventSource domain type — records which external sources contributed to an event listing.

use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::{
    event::EventId,
    source::{SourceId, SourceType},
};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(transparent)]
pub struct EventSourceId(pub Uuid);

impl EventSourceId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for EventSourceId {
    fn default() -> Self {
        Self::new()
    }
}

/// A record linking an event to one external source that reported it.
///
/// # Invariant
///
/// When `source_id` is `Some`, its referenced `Source` row's `source_type` must match
/// the `source_type` field here. Phase 3 adapter code must enforce this invariant when
/// writing `EventSource` rows. The redundancy exists because of the legacy schema
/// migration (V21 added `source_id`; earlier rows only have `source_type`).
#[derive(Debug, Clone, Serialize)]
pub struct EventSource {
    pub id: EventSourceId,
    pub event_id: EventId,
    pub source_type: SourceType,
    pub source_identifier: Option<String>,
    pub source_url: Option<String>,
    pub last_scraped_at: Option<OffsetDateTime>,
    pub confidence_score: Decimal,
    pub created_at: OffsetDateTime,
    pub source_id: Option<SourceId>,
}

/// A single source attribution to attach to an `EventUpsertCommand`.
/// Describes which source reported an event during the ingestion pipeline.
#[derive(Debug, Clone)]
pub struct SourceAttribution {
    pub source_type: SourceType,
    pub source_identifier: Option<String>,
    pub source_url: Option<String>,
    pub confidence_score: Decimal,
    /// Resolved source ID (populated after looking up sources by name/type).
    pub source_id: Option<SourceId>,
}
