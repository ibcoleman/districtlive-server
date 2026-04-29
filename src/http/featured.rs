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
            Err(crate::domain::error::RepoError::NotFound) => None,
            Err(e) => return Err(e.into()),
        }
    } else {
        None
    };

    // Load artists for this event
    use crate::http::dto::{ArtistDto, EventDetailDto, EventDto};
    let artists: Vec<ArtistDto> = match state.artists.find_by_event_id(event.id).await {
        Ok(list) => list.iter().map(ArtistDto::from_artist).collect(),
        Err(crate::domain::error::RepoError::NotFound) => vec![],
        Err(e) => return Err(e.into()),
    };

    // Load related events
    let related: Vec<_> = match state.events.find_related_events(event.id, 7).await {
        Ok(list) => list,
        Err(crate::domain::error::RepoError::NotFound) => vec![],
        Err(e) => return Err(e.into()),
    };
    let related_dtos: Vec<EventDto> = related.iter().map(EventDto::from_event).collect();

    let mut event_dto = EventDto::from_event(&event);
    event_dto.venue = venue_dto;
    event_dto.artists = artists;

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
