use axum::{extract::State, Json};

use crate::http::{dto::FeaturedEventDto, error::ApiError, AppState};

pub async fn get_featured(
    State(state): State<AppState>,
) -> Result<Json<FeaturedEventDto>, ApiError> {
    let featured = state
        .featured
        .find_current()
        .await?
        .ok_or(ApiError::NotFound)?;
    let event = state.events.find_by_id(featured.event_id).await?;

    // Load venue (optional — None if not found or no venue_id)
    let venue_dto = if let Some(venue_id) = event.venue_id {
        match state.venues.find_by_id(venue_id).await {
            Ok(v) => {
                use crate::http::dto::VenueDto;
                Some(VenueDto {
                    id: v.id.0,
                    name: v.effective_name().to_owned(),
                    slug: v.effective_slug().to_owned(),
                    neighborhood: v.neighborhood.clone(),
                    website_url: v.website_url.clone(),
                    upcoming_event_count: 0, // not needed in featured context
                })
            }
            Err(_) => None,
        }
    } else {
        None
    };

    // Load artists for this event
    use crate::http::dto::{ArtistDto, EventDetailDto, EventDto};
    let artists: Vec<ArtistDto> = state
        .artists
        .find_by_event_id(event.id)
        .await
        .unwrap_or_default()
        .iter()
        .map(ArtistDto::from_artist)
        .collect();

    // Load related events
    let related = state
        .events
        .find_related_events(event.id, 7)
        .await
        .unwrap_or_default();
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

    Ok(Json(FeaturedEventDto {
        id: featured.id.0,
        event: EventDetailDto {
            event: event_dto,
            description: event.description,
            end_time: event.end_time,
            sources: vec![],
            related_events: related_dtos,
        },
        blurb: featured.blurb,
        created_at: featured.created_at,
        created_by: featured.created_by,
    }))
}
