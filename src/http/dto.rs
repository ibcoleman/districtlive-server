//! HTTP response data transfer objects.
//!
//! These structs define the JSON wire format. They are constructed from domain
//! types in handler functions and should not contain business logic.
// pattern: Imperative Shell

use rust_decimal::Decimal;
use serde::Serialize;
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::{
    artist::Artist,
    event::{AgeRestriction, EventStatus, PriceTier},
    ingestion_run::{IngestionRun, IngestionRunStatus},
    source::{Source, SourceType},
};

#[derive(Serialize)]
pub struct VenueDto {
    pub id: Uuid,
    pub name: String,
    pub slug: String,
    pub neighborhood: Option<String>,
    pub website_url: Option<String>,
    pub upcoming_event_count: i64,
}

#[derive(Serialize)]
pub struct ArtistDto {
    pub id: Uuid,
    pub name: String,
    pub slug: String,
    pub genres: Vec<String>,
    pub is_local: bool,
    pub spotify_url: Option<String>,
    pub bandcamp_url: Option<String>,
    pub instagram_url: Option<String>,
    pub canonical_name: Option<String>,
    pub image_url: Option<String>,
}

impl ArtistDto {
    pub fn from_artist(a: &Artist) -> Self {
        ArtistDto {
            id: a.id.0,
            name: a.name.clone(),
            slug: a.slug.clone(),
            genres: a.genres.clone(),
            is_local: a.is_local,
            spotify_url: a.spotify_url.clone(),
            bandcamp_url: a.bandcamp_url.clone(),
            instagram_url: a.instagram_url.clone(),
            canonical_name: a.canonical_name.clone(),
            image_url: a.image_url.clone(),
        }
    }
}

#[derive(Serialize)]
pub struct EventDto {
    pub id: Uuid,
    pub title: String,
    pub slug: String,
    #[serde(with = "time::serde::iso8601")]
    pub start_time: OffsetDateTime,
    #[serde(with = "time::serde::iso8601::option")]
    pub doors_time: Option<OffsetDateTime>,
    pub venue: Option<VenueDto>,
    pub artists: Vec<ArtistDto>,
    pub min_price: Option<Decimal>,
    pub max_price: Option<Decimal>,
    pub price_tier: Option<PriceTier>,
    pub ticket_url: Option<String>,
    pub sold_out: bool,
    pub image_url: Option<String>,
    pub age_restriction: AgeRestriction,
    pub status: EventStatus,
    #[serde(with = "time::serde::iso8601")]
    pub created_at: OffsetDateTime,
}

impl EventDto {
    /// Construct an EventDto from a domain Event, with empty venue and artists.
    /// Call sites should hydrate venue and artists separately if needed.
    pub fn from_event(e: &crate::domain::event::Event) -> Self {
        EventDto {
            id: e.id.0,
            title: e.title.clone(),
            slug: e.slug.clone(),
            start_time: e.start_time,
            doors_time: e.doors_time,
            venue: None,
            artists: vec![],
            min_price: e.min_price,
            max_price: e.max_price,
            price_tier: e.price_tier,
            ticket_url: e.ticket_url.clone(),
            sold_out: e.sold_out,
            image_url: e.image_url.clone(),
            age_restriction: e.age_restriction,
            status: e.status,
            created_at: e.created_at,
        }
    }
}

#[derive(Serialize)]
pub struct EventSourceDto {
    pub source_type: SourceType,
    #[serde(with = "time::serde::iso8601::option")]
    pub last_scraped_at: Option<OffsetDateTime>,
}

impl EventSourceDto {
    pub fn from_event_source(s: &crate::domain::event_source::EventSource) -> Self {
        EventSourceDto {
            source_type: s.source_type,
            last_scraped_at: s.last_scraped_at,
        }
    }
}

// Note: #[serde(flatten)] is used here intentionally. The house style prohibits
// #[serde(flatten)] when serde_ignored is involved (deserialization path), because
// it breaks typo detection. EventDetailDto is a *response-only* type: it is only
// serialized (written to JSON), never deserialized. The serde_ignored concern
// applies exclusively to deserialization. Serialization with flatten is safe.
#[derive(Serialize)]
pub struct EventDetailDto {
    #[serde(flatten)]
    pub event: EventDto,
    pub description: Option<String>,
    #[serde(with = "time::serde::iso8601::option")]
    pub end_time: Option<OffsetDateTime>,
    pub sources: Vec<EventSourceDto>,
    pub related_events: Vec<EventDto>,
}

#[derive(Serialize)]
pub struct FeaturedEventDto {
    pub id: Uuid,
    pub event: EventDetailDto,
    pub blurb: String,
    #[serde(with = "time::serde::iso8601")]
    pub created_at: OffsetDateTime,
    pub created_by: String,
}

#[derive(Serialize)]
pub struct SourceHealthDto {
    pub id: Uuid,
    pub name: String,
    pub source_type: SourceType,
    #[serde(with = "time::serde::iso8601::option")]
    pub last_success_at: Option<OffsetDateTime>,
    #[serde(with = "time::serde::iso8601::option")]
    pub last_failure_at: Option<OffsetDateTime>,
    pub consecutive_failures: i32,
    pub healthy: bool,
}

impl SourceHealthDto {
    pub fn from_source(s: &Source) -> Self {
        SourceHealthDto {
            id: s.id.0,
            name: s.name.clone(),
            source_type: s.source_type,
            last_success_at: s.last_success_at,
            last_failure_at: s.last_failure_at,
            consecutive_failures: s.consecutive_failures,
            healthy: s.healthy,
        }
    }
}

#[derive(Serialize)]
pub struct IngestionRunDto {
    pub id: Uuid,
    pub source_id: Uuid,
    pub status: IngestionRunStatus,
    pub events_fetched: i32,
    pub events_created: i32,
    pub events_updated: i32,
    pub events_deduplicated: i32,
    pub error_message: Option<String>,
    #[serde(with = "time::serde::iso8601")]
    pub started_at: OffsetDateTime,
    #[serde(with = "time::serde::iso8601::option")]
    pub completed_at: Option<OffsetDateTime>,
}

impl IngestionRunDto {
    pub fn from_run(r: &IngestionRun) -> Self {
        IngestionRunDto {
            id: r.id.0,
            source_id: r.source_id.0,
            status: r.status,
            events_fetched: r.events_fetched,
            events_created: r.events_created,
            events_updated: r.events_updated,
            events_deduplicated: r.events_deduplicated,
            error_message: r.error_message.clone(),
            started_at: r.started_at,
            completed_at: r.completed_at,
        }
    }
}

#[derive(Serialize)]
pub struct PageDto<T: Serialize> {
    pub items: Vec<T>,
    pub total: i64,
    pub page: i64,
    pub per_page: i64,
}
