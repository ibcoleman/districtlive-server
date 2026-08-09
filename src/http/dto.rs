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
#[serde(rename_all = "camelCase")]
pub struct VenueDto {
    pub id: Uuid,
    pub name: String,
    pub slug: String,
    pub neighborhood: Option<String>,
    pub website_url: Option<String>,
    pub upcoming_event_count: i64,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
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
#[serde(rename_all = "camelCase")]
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
    #[serde(with = "time::serde::iso8601::option")]
    pub on_sale_date: Option<OffsetDateTime>,
    pub ticket_platform: Option<String>,
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
            on_sale_date: e.on_sale_date,
            ticket_platform: e.ticket_platform.clone(),
        }
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct EventSourceDto {
    pub source_type: SourceType,
    #[serde(with = "time::serde::iso8601::option")]
    pub last_scraped_at: Option<OffsetDateTime>,
}

// Note: #[serde(flatten)] is used here intentionally. The house style prohibits
// #[serde(flatten)] when serde_ignored is involved (deserialization path), because
// it breaks typo detection. EventDetailDto is a *response-only* type: it is only
// serialized (written to JSON), never deserialized. The serde_ignored concern
// applies exclusively to deserialization. Serialization with flatten is safe.
#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
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
#[serde(rename_all = "camelCase")]
pub struct FeaturedEventDto {
    pub id: Uuid,
    pub event: EventDetailDto,
    pub blurb: String,
    #[serde(with = "time::serde::iso8601")]
    pub created_at: OffsetDateTime,
    pub created_by: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
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
#[serde(rename_all = "camelCase")]
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

/// Paginated response matching Spring's `Page<T>` JSON format.
///
/// The Flutter app's `PageResponse<T>` expects these exact field names:
/// `content`, `number`, `size`, `totalElements`, `totalPages`, `first`, `last`, `empty`.
#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PageDto<T: Serialize> {
    pub content: Vec<T>,
    pub number: i64,
    pub size: i64,
    pub total_elements: i64,
    pub total_pages: i64,
    pub first: bool,
    pub last: bool,
    pub empty: bool,
}

impl<T: Serialize> PageDto<T> {
    /// Build a Spring-Page-shaped response from the raw pagination data.
    ///
    /// `page` is 0-indexed. When `total == 0`, `total_pages == 0`, `first == true`,
    /// `last == true`, and `empty == true` — matching Spring Data's behavior.
    pub fn from_page(content: Vec<T>, total: i64, page: i64, size: i64) -> Self {
        let total_pages = if size > 0 {
            (total + size - 1) / size
        } else {
            0
        };
        Self {
            content,
            number: page,
            size,
            total_elements: total,
            total_pages,
            first: page == 0,
            last: page >= total_pages.saturating_sub(1) || total == 0,
            empty: total == 0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::event::{AgeRestriction, EventStatus, EventType, PriceTier};
    use crate::domain::source::SourceType;
    use rust_decimal::Decimal;
    use time::OffsetDateTime;

    // AC.1 — DTOs serialize with camelCase field names
    #[test]
    fn test_dto_serializes_camel_case() {
        let dto = EventDto {
            id: Uuid::nil(),
            title: "Test Event".into(),
            slug: "test-event".into(),
            start_time: OffsetDateTime::now_utc(),
            doors_time: None,
            venue: None,
            artists: vec![],
            min_price: None,
            max_price: None,
            price_tier: None,
            ticket_url: None,
            sold_out: false,
            image_url: None,
            age_restriction: AgeRestriction::AllAges,
            status: EventStatus::Active,
            created_at: OffsetDateTime::now_utc(),
            on_sale_date: None,
            ticket_platform: None,
        };
        let json = serde_json::to_value(&dto).unwrap();
        let obj = json.as_object().unwrap();
        // camelCase keys, not snake_case
        assert!(obj.contains_key("startTime"), "expected startTime key");
        assert!(obj.contains_key("createdAt"), "expected createdAt key");
        assert!(obj.contains_key("ticketUrl"), "expected ticketUrl key");
        assert!(obj.contains_key("minPrice"), "expected minPrice key");
        assert!(obj.contains_key("onSaleDate"), "expected onSaleDate key");
        assert!(
            obj.contains_key("ticketPlatform"),
            "expected ticketPlatform key"
        );
        // Must NOT contain snake_case keys
        assert!(
            !obj.contains_key("start_time"),
            "found snake_case start_time"
        );
        assert!(
            !obj.contains_key("ticket_url"),
            "found snake_case ticket_url"
        );
    }

    // AC.2 — PageDto matches Spring Page format
    #[test]
    fn test_page_dto_matches_spring_format() {
        let page = PageDto::from_page(vec!["a".to_string()], 30, 1, 10);
        let json = serde_json::to_value(&page).unwrap();
        let obj = json.as_object().unwrap();
        assert!(obj.contains_key("content"), "expected content");
        assert!(obj.contains_key("number"), "expected number");
        assert!(obj.contains_key("size"), "expected size");
        assert!(obj.contains_key("totalElements"), "expected totalElements");
        assert!(obj.contains_key("totalPages"), "expected totalPages");
        assert!(obj.contains_key("first"), "expected first");
        assert!(obj.contains_key("last"), "expected last");
        assert!(obj.contains_key("empty"), "expected empty");
        // Check derived values
        assert_eq!(obj["number"], 1);
        assert_eq!(obj["size"], 10);
        assert_eq!(obj["totalElements"], 30);
        assert_eq!(obj["totalPages"], 3);
        assert_eq!(obj["first"], false);
        assert_eq!(obj["last"], false);
        assert_eq!(obj["empty"], false);
    }

    // AC.2 edge case — empty result
    #[test]
    fn test_page_dto_empty() {
        let page: PageDto<String> = PageDto::from_page(vec![], 0, 0, 10);
        let json = serde_json::to_value(&page).unwrap();
        let obj = json.as_object().unwrap();
        assert_eq!(obj["totalPages"], 0);
        assert_eq!(obj["first"], true);
        assert_eq!(obj["last"], true);
        assert_eq!(obj["empty"], true);
    }

    // AC.6 — Decimal serializes as JSON number, not string
    #[test]
    fn test_decimal_serializes_as_number() {
        let dto = EventDto {
            id: Uuid::nil(),
            title: "Test".into(),
            slug: "test".into(),
            start_time: OffsetDateTime::now_utc(),
            doors_time: None,
            venue: None,
            artists: vec![],
            min_price: Some(Decimal::new(2500, 2)), // 25.00
            max_price: Some(Decimal::new(3500, 2)), // 35.00
            price_tier: Some(PriceTier::Price15To30),
            ticket_url: None,
            sold_out: false,
            image_url: None,
            age_restriction: AgeRestriction::AllAges,
            status: EventStatus::Active,
            created_at: OffsetDateTime::now_utc(),
            on_sale_date: None,
            ticket_platform: None,
        };
        let json = serde_json::to_value(&dto).unwrap();
        // minPrice must be a JSON number, not a string
        assert!(
            json["minPrice"].is_number(),
            "minPrice should be a number, got: {}",
            json["minPrice"]
        );
        assert!(
            json["maxPrice"].is_number(),
            "maxPrice should be a number, got: {}",
            json["maxPrice"]
        );
    }

    // AC.7 — Enum variants serialize as SCREAMING_SNAKE_CASE
    #[test]
    fn test_enum_screaming_snake_case() {
        assert_eq!(
            serde_json::to_value(EventType::DjSet).unwrap(),
            serde_json::json!("DJ_SET")
        );
        assert_eq!(
            serde_json::to_value(SourceType::DiceFm).unwrap(),
            serde_json::json!("DICE_FM")
        );
        assert_eq!(
            serde_json::to_value(SourceType::TicketmasterApi).unwrap(),
            serde_json::json!("TICKETMASTER_API")
        );
        assert_eq!(
            serde_json::to_value(PriceTier::Price15To30).unwrap(),
            serde_json::json!("PRICE_15_TO_30")
        );
        assert_eq!(
            serde_json::to_value(EventStatus::Cancelled).unwrap(),
            serde_json::json!("CANCELLED")
        );
        assert_eq!(
            serde_json::to_value(AgeRestriction::AllAges).unwrap(),
            serde_json::json!("ALL_AGES")
        );
        assert_eq!(
            serde_json::to_value(AgeRestriction::EighteenPlus).unwrap(),
            serde_json::json!("EIGHTEEN_PLUS")
        );
        assert_eq!(
            serde_json::to_value(SourceType::BandsintownApi).unwrap(),
            serde_json::json!("BANDSINTOWN_API")
        );
    }

    // AC.7 — EventDto priceTier enum in context
    #[test]
    fn test_price_tier_in_dto_is_screaming_snake_case() {
        let dto = EventDto {
            id: Uuid::nil(),
            title: "Test".into(),
            slug: "test".into(),
            start_time: OffsetDateTime::now_utc(),
            doors_time: None,
            venue: None,
            artists: vec![],
            min_price: None,
            max_price: None,
            price_tier: Some(PriceTier::Under15),
            ticket_url: None,
            sold_out: false,
            image_url: None,
            age_restriction: AgeRestriction::AllAges,
            status: EventStatus::Active,
            created_at: OffsetDateTime::now_utc(),
            on_sale_date: None,
            ticket_platform: None,
        };
        let json = serde_json::to_value(&dto).unwrap();
        assert_eq!(json["priceTier"], "UNDER_15");
        assert_eq!(json["ageRestriction"], "ALL_AGES");
        assert_eq!(json["status"], "ACTIVE");
    }
}
