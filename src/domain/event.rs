//! Event domain types — the central entity of the system.
//!
//! Also contains ingestion pipeline types (RawEvent, NormalizedEvent,
//! DeduplicatedEvent, EventUpsertCommand) since they describe events
//! at different stages of processing.

use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::{event_source::SourceAttribution, venue::VenueId};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(transparent)]
pub struct EventId(pub Uuid);

impl EventId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for EventId {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Display for EventId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.0.fmt(f)
    }
}

/// Lifecycle status of an event listing.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, Default, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum EventStatus {
    #[default]
    Active,
    Cancelled,
    Postponed,
    Rescheduled,
}

/// Broad price tier for faceted filtering.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum PriceTier {
    Free,
    Under15,
    Price15To30,
    Over30,
}

/// Age restriction policy for the event.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, Default, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum AgeRestriction {
    #[default]
    AllAges,
    EighteenPlus,
    TwentyOnePlus,
}

/// Genre/format classification for an event.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum EventType {
    Concert,
    AlbumRelease,
    Showcase,
    Tribute,
    DjSet,
    Other,
}

#[derive(Debug, Clone, Serialize)]
pub struct Event {
    pub id: EventId,
    pub title: String,
    pub slug: String,
    pub description: Option<String>,
    pub start_time: OffsetDateTime,
    pub end_time: Option<OffsetDateTime>,
    pub doors_time: Option<OffsetDateTime>,
    pub min_price: Option<Decimal>,
    pub max_price: Option<Decimal>,
    pub price_tier: Option<PriceTier>,
    pub ticket_url: Option<String>,
    pub on_sale_date: Option<OffsetDateTime>,
    pub sold_out: bool,
    pub ticket_platform: Option<String>,
    pub image_url: Option<String>,
    pub age_restriction: AgeRestriction,
    pub status: EventStatus,
    pub venue_id: Option<VenueId>,
    pub title_parsed: bool,
    pub event_type: Option<EventType>,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
}

// ---------------------------------------------------------------------------
// Ingestion pipeline types
// ---------------------------------------------------------------------------

/// Unprocessed event data as returned directly by a `SourceConnector::fetch()` call.
/// Fields are as-received from the external source — no normalization applied.
#[derive(Debug, Clone)]
pub struct RawEvent {
    pub source_type: crate::domain::source::SourceType,
    pub source_identifier: Option<String>,
    pub source_url: Option<String>,
    pub title: String,
    pub description: Option<String>,
    pub venue_name: String,
    pub venue_address: Option<String>,
    pub artist_names: Vec<String>,
    pub start_time: OffsetDateTime,
    pub end_time: Option<OffsetDateTime>,
    pub doors_time: Option<OffsetDateTime>,
    pub min_price: Option<Decimal>,
    pub max_price: Option<Decimal>,
    pub ticket_url: Option<String>,
    pub image_url: Option<String>,
    pub age_restriction: Option<String>,
    pub genres: Vec<String>,
    pub confidence_score: Decimal,
}

/// A `RawEvent` after title cleaning, slug generation, and time normalization.
#[derive(Debug, Clone)]
pub struct NormalizedEvent {
    pub raw: RawEvent,
    /// URL-safe slug derived from title + venue_name + date (e.g. `the-national-9-30-club-2026-05-15`).
    pub slug: String,
}

/// One or more `NormalizedEvent`s that share the same slug, merged into a single record.
#[derive(Debug, Clone)]
pub struct DeduplicatedEvent {
    /// The canonical version of the event (first seen or highest-confidence).
    pub event: NormalizedEvent,
    /// All source attributions gathered from duplicate events with the same slug.
    pub sources: Vec<SourceAttribution>,
}

/// Command passed to `EventRepository::upsert` to create or update an event.
#[derive(Debug, Clone)]
pub struct EventUpsertCommand {
    pub slug: String,
    pub title: String,
    pub description: Option<String>,
    pub start_time: OffsetDateTime,
    pub end_time: Option<OffsetDateTime>,
    pub doors_time: Option<OffsetDateTime>,
    /// Venue name used to resolve or create the venue record.
    pub venue_name: String,
    pub venue_address: Option<String>,
    /// Artist names used to resolve or create artist records.
    pub artist_names: Vec<String>,
    pub min_price: Option<Decimal>,
    pub max_price: Option<Decimal>,
    pub price_tier: Option<PriceTier>,
    pub ticket_url: Option<String>,
    pub image_url: Option<String>,
    pub age_restriction: AgeRestriction,
    /// All source attributions to associate with this event.
    pub source_attributions: Vec<SourceAttribution>,
}

/// Filters passed to `EventRepository::find_all`.
#[derive(Debug, Clone, Default)]
pub struct EventFilters {
    pub date_from: Option<OffsetDateTime>,
    pub date_to: Option<OffsetDateTime>,
    pub venue_slug: Option<String>,
    pub genre: Option<String>,
    pub neighborhood: Option<String>,
    pub price_max: Option<Decimal>,
    pub status: Option<EventStatus>,
}
