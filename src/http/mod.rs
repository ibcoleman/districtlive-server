pub mod admin;
pub mod artists;
pub mod dto;
pub mod error;
pub mod events;
pub mod featured;
pub mod middleware;
pub mod venues;
pub mod version;

use crate::config::Config;
use crate::ports::{
    ArtistRepository, EventRepository, FeaturedEventRepository, IngestionRunRepository,
    SourceRepository, VenueRepository,
};
use axum::{
    body::Body,
    extract::Path,
    http::{header, StatusCode},
    response::{IntoResponse, Response},
    routing::{get, post},
};
use rust_embed::RustEmbed;
use std::sync::Arc;
use tower_http::trace::TraceLayer;

#[derive(RustEmbed)]
#[folder = "frontend/dist/"]
struct Assets;

#[derive(Clone)]
pub struct AppState {
    pub config: Arc<Config>,
    pub venues: Arc<dyn VenueRepository>,
    pub artists: Arc<dyn ArtistRepository>,
    pub events: Arc<dyn EventRepository>,
    pub featured: Arc<dyn FeaturedEventRepository>,
    pub sources: Arc<dyn SourceRepository>,
    pub ingestion_runs: Arc<dyn IngestionRunRepository>,
}

pub fn create_router(state: AppState) -> axum::Router {
    // Admin sub-router — protected by Basic auth middleware
    let admin_router = axum::Router::new()
        .route("/api/admin/sources", get(admin::list_sources))
        .route(
            "/api/admin/sources/{id}/history",
            get(admin::get_source_history),
        )
        .route(
            "/api/admin/ingest/trigger",
            post(admin::trigger_all_ingestion),
        )
        .route(
            "/api/admin/ingest/trigger/{source_id}",
            post(admin::trigger_source_ingestion),
        )
        .route(
            "/api/admin/featured/history",
            get(admin::get_featured_history),
        )
        .route("/api/admin/featured", post(admin::create_featured))
        .route_layer(axum::middleware::from_fn_with_state(
            state.clone(),
            middleware::basic_auth::require_basic_auth,
        ));

    // Public router
    let public_router = axum::Router::new()
        .route("/healthz", get(healthz))
        .route("/api/version", get(version::get_version))
        .route("/api/events", get(events::list_events))
        .route("/api/events/{id}", get(events::get_event))
        .route("/api/venues", get(venues::list_venues))
        .route("/api/venues/{id}", get(venues::get_venue))
        .route("/api/artists", get(artists::list_artists))
        .route("/api/artists/{id}", get(artists::get_artist))
        .route("/api/featured", get(featured::get_featured))
        // Static assets from embedded frontend
        .route("/", get(index))
        .route("/assets/{*path}", get(asset));

    public_router
        .merge(admin_router)
        .layer(TraceLayer::new_for_http())
        .with_state(state)
}

async fn healthz() -> axum::Json<serde_json::Value> {
    axum::Json(serde_json::json!({ "status": "ok" }))
}

async fn index() -> Response {
    match Assets::get("index.html") {
        Some(f) => Response::builder()
            .header(header::CONTENT_TYPE, "text/html; charset=utf-8")
            .body(Body::from(f.data.into_owned()))
            .unwrap_or_else(|_| StatusCode::INTERNAL_SERVER_ERROR.into_response()),
        None => (StatusCode::INTERNAL_SERVER_ERROR, "index.html missing").into_response(),
    }
}

async fn asset(Path(path): Path<String>) -> Response {
    let full = format!("assets/{path}");
    match Assets::get(&full) {
        Some(f) => {
            let mime = mime_guess::from_path(&full).first_or_octet_stream();
            Response::builder()
                .header(header::CONTENT_TYPE, mime.as_ref())
                .body(Body::from(f.data.into_owned()))
                .unwrap_or_else(|_| StatusCode::INTERNAL_SERVER_ERROR.into_response())
        }
        None => StatusCode::NOT_FOUND.into_response(),
    }
}
