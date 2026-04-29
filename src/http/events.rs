use axum::{
    extract::{Path, Query, State},
    Json,
};
use rust_decimal::Decimal;
use serde::Deserialize;
use time::OffsetDateTime;
use uuid::Uuid;

use crate::{
    domain::event::{EventFilters, EventStatus},
    domain::Pagination,
    http::{
        dto::{EventDetailDto, EventDto, PageDto},
        error::ApiError,
        AppState,
    },
};

/// Query parameters for GET /api/events
#[derive(Deserialize, Default)]
pub struct EventsQuery {
    #[serde(default, with = "time::serde::iso8601::option")]
    pub date_from: Option<OffsetDateTime>,
    #[serde(default, with = "time::serde::iso8601::option")]
    pub date_to: Option<OffsetDateTime>,
    pub venue_slug: Option<String>,
    pub genre: Option<String>,
    pub neighborhood: Option<String>,
    pub price_max: Option<Decimal>,
    pub status: Option<EventStatus>,
    #[serde(default)]
    pub page: i64,
    #[serde(default = "default_per_page")]
    pub per_page: i64,
}

fn default_per_page() -> i64 {
    20
}

pub async fn list_events(
    State(state): State<AppState>,
    Query(q): Query<EventsQuery>,
) -> Result<Json<PageDto<EventDto>>, ApiError> {
    let filters = EventFilters {
        date_from: q.date_from,
        date_to: q.date_to,
        venue_slug: q.venue_slug,
        genre: q.genre,
        neighborhood: q.neighborhood,
        price_max: q.price_max,
        status: q.status,
    };
    let page = Pagination {
        page: q.page,
        per_page: q.per_page,
    };
    let result = state.events.find_all(filters, page).await?;

    // Build EventDto for each event (venue detail not included in list — add Phase 4 extension)
    let items = result
        .items
        .iter()
        .map(|e| EventDto {
            id: e.id.0,
            title: e.title.clone(),
            slug: e.slug.clone(),
            start_time: e.start_time,
            doors_time: e.doors_time,
            venue: None,     // Populated below with venue lookup
            artists: vec![], // Populated with artist lookup
            min_price: e.min_price,
            max_price: e.max_price,
            price_tier: e.price_tier,
            ticket_url: e.ticket_url.clone(),
            sold_out: e.sold_out,
            image_url: e.image_url.clone(),
            age_restriction: e.age_restriction,
            status: e.status,
            created_at: e.created_at,
        })
        .collect();

    Ok(Json(PageDto {
        items,
        total: result.total,
        page: result.page,
        per_page: result.per_page,
    }))
}

/// Get event detail by UUID path parameter.
///
/// Note: a malformed UUID in the path returns 400 (axum path extraction failure).
/// A valid UUID that doesn't match any event returns 404 (domain NotFound).
/// Both are intentional — 400 for invalid input, 404 for missing resource.
pub async fn get_event(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<EventDetailDto>, ApiError> {
    use crate::domain::event::EventId;
    use crate::http::dto::{ArtistDto, VenueDto};

    let event = state.events.find_by_id(EventId(id)).await?;
    let related = state.events.find_related_events(event.id, 7).await?;

    // Load venue (optional — None if not found or no venue_id)
    let venue_dto = if let Some(venue_id) = event.venue_id {
        match state.venues.find_by_id(venue_id).await {
            Ok(v) => Some(VenueDto {
                id: v.id.0,
                name: v.effective_name().to_owned(),
                slug: v.effective_slug().to_owned(),
                neighborhood: v.neighborhood.clone(),
                website_url: v.website_url.clone(),
                upcoming_event_count: 0, // not needed in event detail context
            }),
            Err(_) => None,
        }
    } else {
        None
    };

    // Load artists for this event
    let artists: Vec<ArtistDto> = state
        .artists
        .find_by_event_id(event.id)
        .await
        .unwrap_or_default()
        .iter()
        .map(ArtistDto::from_artist)
        .collect();

    let event_dto = EventDto {
        id: event.id.0,
        title: event.title.clone(),
        slug: event.slug.clone(),
        start_time: event.start_time,
        doors_time: event.doors_time,
        venue: venue_dto,
        artists,
        min_price: event.min_price,
        max_price: event.max_price,
        price_tier: event.price_tier,
        ticket_url: event.ticket_url.clone(),
        sold_out: event.sold_out,
        image_url: event.image_url.clone(),
        age_restriction: event.age_restriction,
        status: event.status,
        created_at: event.created_at,
    };

    let related_dtos = related
        .iter()
        .map(|e| EventDto {
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
        })
        .collect();

    Ok(Json(EventDetailDto {
        event: event_dto,
        description: event.description,
        end_time: event.end_time,
        sources: vec![], // TODO: load event_sources
        related_events: related_dtos,
    }))
}
