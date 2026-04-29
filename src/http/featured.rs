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

    // Build full detail (simplified — venues/artists/sources require additional queries)
    use crate::http::dto::{EventDetailDto, EventDto};
    let event_dto = EventDto {
        id: event.id.0,
        title: event.title.clone(),
        slug: event.slug.clone(),
        start_time: event.start_time,
        doors_time: event.doors_time,
        venue: None,
        artists: vec![],
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
            related_events: vec![],
        },
        blurb: featured.blurb,
        created_at: featured.created_at,
        created_by: featured.created_by,
    }))
}
