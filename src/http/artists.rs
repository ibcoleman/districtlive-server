// pattern: Imperative Shell
use axum::{
    extract::{Path, Query, State},
    Json,
};
use serde::Deserialize;
use uuid::Uuid;

use crate::{
    domain::Pagination,
    http::{
        dto::{ArtistDto, PageDto},
        error::ApiError,
        AppState,
    },
};

#[derive(Deserialize, Default)]
pub struct ArtistsQuery {
    pub name: Option<String>,
    #[serde(default)]
    pub local: bool,
    #[serde(default)]
    pub page: i64,
    #[serde(default = "default_per_page")]
    pub per_page: i64,
}

fn default_per_page() -> i64 {
    20
}

pub async fn list_artists(
    State(state): State<AppState>,
    Query(q): Query<ArtistsQuery>,
) -> Result<Json<PageDto<ArtistDto>>, ApiError> {
    if q.local {
        let artists = state.artists.find_local().await?;
        let count = i64::try_from(artists.len()).unwrap_or(i64::MAX);
        let dtos = artists.iter().map(ArtistDto::from_artist).collect();
        return Ok(Json(PageDto {
            items: dtos,
            total: count,
            page: 0,
            per_page: count,
        }));
    }
    if let Some(name) = &q.name {
        let artist = state.artists.find_by_name(name).await?;
        let items = artist
            .iter()
            .map(ArtistDto::from_artist)
            .collect::<Vec<_>>();
        let count = i64::try_from(items.len()).unwrap_or(i64::MAX);
        return Ok(Json(PageDto {
            items,
            total: count,
            page: 0,
            per_page: count,
        }));
    }
    let page = state
        .artists
        .find_all(Pagination {
            page: q.page,
            per_page: q.per_page,
        })
        .await?;
    let dtos = page.items.iter().map(ArtistDto::from_artist).collect();
    Ok(Json(PageDto {
        items: dtos,
        total: page.total,
        page: page.page,
        per_page: page.per_page,
    }))
}

pub async fn get_artist(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<ArtistDto>, ApiError> {
    use crate::domain::artist::ArtistId;
    let artist = state.artists.find_by_id(ArtistId(id)).await?;
    Ok(Json(ArtistDto::from_artist(&artist)))
}
