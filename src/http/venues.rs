use axum::{
    extract::{Path, Query, State},
    Json,
};
use serde::Deserialize;
use uuid::Uuid;

use crate::{
    domain::Pagination,
    http::{
        dto::{PageDto, VenueDto},
        error::ApiError,
        AppState,
    },
};

#[derive(Deserialize, Default)]
pub struct VenuesQuery {
    pub neighborhood: Option<String>,
    #[serde(default)]
    pub page: i64,
    #[serde(default = "default_per_page")]
    pub per_page: i64,
}

fn default_per_page() -> i64 {
    20
}

pub async fn list_venues(
    State(state): State<AppState>,
    Query(q): Query<VenuesQuery>,
) -> Result<Json<PageDto<VenueDto>>, ApiError> {
    // If neighborhood filter, use filtered query; otherwise paginated list
    let (items, total) = if let Some(ref neighborhood) = q.neighborhood {
        let venues = state.venues.find_by_neighborhood(neighborhood).await?;
        let count = venues.len() as i64;
        (venues, count)
    } else {
        let page = state
            .venues
            .find_all(Pagination {
                page: q.page,
                per_page: q.per_page,
            })
            .await?;
        let total = page.total;
        (page.items, total)
    };

    // Get upcoming event counts per venue
    let counts = state.events.count_upcoming_by_venue().await?;
    let count_map: std::collections::HashMap<_, _> = counts.into_iter().collect();

    let dtos = items
        .iter()
        .map(|v| VenueDto {
            id: v.id.0,
            name: v.effective_name().to_owned(),
            slug: v.effective_slug().to_owned(),
            neighborhood: v.neighborhood.clone(),
            website_url: v.website_url.clone(),
            upcoming_event_count: count_map.get(&v.id).copied().unwrap_or(0),
        })
        .collect();

    Ok(Json(PageDto {
        items: dtos,
        total,
        page: q.page,
        per_page: q.per_page,
    }))
}

pub async fn get_venue(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<VenueDto>, ApiError> {
    use crate::domain::venue::VenueId;
    let venue = state.venues.find_by_id(VenueId(id)).await?;
    let counts = state.events.count_upcoming_by_venue().await?;
    let count_map: std::collections::HashMap<_, _> = counts.into_iter().collect();
    let upcoming = count_map.get(&venue.id).copied().unwrap_or(0);

    Ok(Json(VenueDto {
        id: venue.id.0,
        name: venue.effective_name().to_owned(),
        slug: venue.effective_slug().to_owned(),
        neighborhood: venue.neighborhood.clone(),
        website_url: venue.website_url.clone(),
        upcoming_event_count: upcoming,
    }))
}
