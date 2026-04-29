# DistrictLive Rust Port — Phase 4: HTTP API + Admin

**Goal:** All HTTP endpoints functional. Public API queryable. Admin routes protected by HTTP Basic auth. 400/401/404 error responses match the Kotlin app's contract.

**Architecture:** Handlers in `src/http/` modules. Admin routes on a sub-router with a Tower middleware layer for HTTP Basic auth. Response DTOs live in `src/http/dto.rs`. `ApiError` converts domain errors to HTTP responses. The `time::OffsetDateTime` query parameter deserialization uses `time::serde::iso8601` with serde's `with` attribute.

**Tech Stack:** axum 0.8, axum-extra 0.10 (typed-header), tower middleware, serde with time::serde::iso8601

**Scope:** Phase 4 of 7 from original design

**Codebase verified:** 2026-04-29

---

## Acceptance Criteria Coverage

### rust-port.AC2: Public read API
- **rust-port.AC2.1 Success:** `GET /api/events` returns a paginated JSON list with correct shape (title, slug, venue, artists, start_time, price, status)
- **rust-port.AC2.2 Success:** `GET /api/events` with `date_from`, `date_to`, `venue_slug`, `genre`, `neighborhood`, `price_max`, and `status` filters each independently narrow results
- **rust-port.AC2.3 Success:** `GET /api/events/{id}` returns full event detail including venue object, artist list, and related events at the same venue within ±7 days
- **rust-port.AC2.4 Success:** `GET /api/venues` with `neighborhood` filter returns only venues in that neighborhood
- **rust-port.AC2.5 Success:** `GET /api/artists` with `local=true` returns only artists flagged as local
- **rust-port.AC2.6 Success:** `GET /api/featured` returns the most recently created featured event with full event detail and blurb
- **rust-port.AC2.7 Failure:** `GET /api/events/{id}` with an unknown UUID returns 404
- **rust-port.AC2.8 Failure:** `GET /api/events` with a malformed `date_from` returns 400

### rust-port.AC5: Admin API and HTTP Basic auth
- **rust-port.AC5.1 Success:** `GET /api/admin/sources` with valid credentials returns all sources with health fields (last_success_at, consecutive_failures, healthy flag)
- **rust-port.AC5.2 Success:** `GET /api/admin/sources/{id}/history` returns ingestion run history for the specified source, ordered by `started_at` descending
- **rust-port.AC5.3 Success:** `POST /api/admin/featured` with a valid event UUID and non-blank blurb creates and returns the featured event
- **rust-port.AC5.4 Failure:** Any `/api/admin/*` request without an `Authorization` header returns 401
- **rust-port.AC5.5 Failure:** Any `/api/admin/*` request with incorrect credentials returns 401
- **rust-port.AC5.6 Failure:** `POST /api/admin/featured` with a blank blurb returns 400
- **rust-port.AC5.7 Failure:** `POST /api/admin/featured` with an unknown event UUID returns 404

---

## Prerequisite: Add `parsing` feature to `time`

Before writing handlers, add the `"parsing"` feature to the `time` dependency in `Cargo.toml`. This feature is required for `OffsetDateTime` deserialization from query strings via `time::serde::iso8601`.

Read `Cargo.toml`. Find the `time` entry and update its features to include `"parsing"`:

```toml
time = { version = "0.3", features = ["formatting", "parsing", "serde"] }
```

No bazel-repin needed — `time` is already pinned in the lockfile; adding a feature doesn't add a new crate.

---

<!-- START_SUBCOMPONENT_A (tasks 1-3) -->

<!-- START_TASK_1 -->
### Task 1: Extended ApiError + response DTOs

**Verifies:** rust-port.AC2.7, rust-port.AC2.8, rust-port.AC5.4, rust-port.AC5.5

**Files:**
- Modify: `src/http/error.rs` — add Unauthorized, extend domain error conversions
- Create: `src/http/dto.rs` — response DTO structs

**Step 1: Replace src/http/error.rs**

```rust
//! HTTP error type. Converts domain errors to HTTP responses.

use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;

use crate::domain::error::{EnrichmentError, IngestionError, RepoError};

#[derive(Debug, thiserror::Error)]
pub enum ApiError {
    #[error("bad request: {0}")]
    BadRequest(String),
    #[error("not found")]
    NotFound,
    #[error("unauthorized")]
    Unauthorized,
    #[error("internal server error: {0}")]
    Internal(String),
    #[error(transparent)]
    Repo(#[from] RepoError),
    #[error(transparent)]
    Ingestion(#[from] IngestionError),
}

impl From<EnrichmentError> for ApiError {
    fn from(e: EnrichmentError) -> Self {
        ApiError::Internal(e.to_string())
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, message) = match &self {
            ApiError::BadRequest(m) => (StatusCode::BAD_REQUEST, m.clone()),
            ApiError::NotFound => (StatusCode::NOT_FOUND, "not found".to_owned()),
            ApiError::Unauthorized => (StatusCode::UNAUTHORIZED, "unauthorized".to_owned()),
            ApiError::Internal(m) => (StatusCode::INTERNAL_SERVER_ERROR, m.clone()),
            ApiError::Repo(RepoError::NotFound) => (StatusCode::NOT_FOUND, "not found".to_owned()),
            ApiError::Repo(RepoError::Database(e)) => {
                tracing::error!("Database error: {e}");
                (StatusCode::INTERNAL_SERVER_ERROR, "database error".to_owned())
            }
            ApiError::Ingestion(IngestionError::Disabled) => {
                (StatusCode::BAD_REQUEST, "ingestion is disabled".to_owned())
            }
            ApiError::Ingestion(e) => {
                tracing::error!("Ingestion error: {e}");
                (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
            }
        };

        (status, Json(json!({ "error": message }))).into_response()
    }
}
```

**Step 2: Create src/http/dto.rs**

These structs are the JSON wire format for all public and admin endpoints. They mirror the Kotlin DTO shapes.

```rust
//! HTTP response data transfer objects.
//!
//! These structs define the JSON wire format. They are constructed from domain
//! types in handler functions and should not contain business logic.

use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::{
    artist::Artist,
    event::{AgeRestriction, Event, EventStatus, EventType, PriceTier},
    event_source::EventSource,
    featured_event::FeaturedEvent,
    ingestion_run::{IngestionRun, IngestionRunStatus},
    source::{Source, SourceType},
    venue::Venue,
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

#[derive(Serialize)]
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
```

**Step 3: Update src/http/mod.rs to expose dto module**

Add `pub mod dto;` to the module declarations in `src/http/mod.rs`.

**Verify:**

```bash
cargo check 2>&1 | grep "error\[" | head -10
```

**Commit:** `feat: extended ApiError, response DTOs`
<!-- END_TASK_1 -->

<!-- START_TASK_2 -->
### Task 2: Basic auth middleware

**Verifies:** rust-port.AC5.4, rust-port.AC5.5

**Files:**
- Create: `src/http/middleware/basic_auth.rs`
- Create: `src/http/middleware/mod.rs`
- Modify: `src/http/mod.rs` — add `pub mod middleware;`

**Step 1: Create src/http/middleware/mod.rs**

```rust
pub mod basic_auth;
```

**Step 2: Create src/http/middleware/basic_auth.rs**

The middleware must return 401 for BOTH missing Authorization header AND wrong credentials. `TypedHeader<Authorization<Basic>>` returns 400 (not 401) for missing headers, so we read the raw header bytes instead.

```rust
//! HTTP Basic authentication Tower middleware for the admin API.
//!
//! Returns 401 Unauthorized for:
//! - Missing `Authorization` header
//! - Malformed `Authorization` header
//! - Incorrect username or password

use axum::{
    extract::{Request, State},
    middleware::Next,
    response::{IntoResponse, Response},
};

use crate::http::error::ApiError;
use crate::http::AppState;

/// Tower middleware: validate HTTP Basic auth against Config admin credentials.
///
/// Apply to admin routes via:
/// ```rust
/// admin_router.route_layer(axum::middleware::from_fn_with_state(state, require_basic_auth))
/// ```
pub async fn require_basic_auth(
    State(state): State<AppState>,
    request: Request,
    next: Next,
) -> Result<Response, ApiError> {
    let auth_header = request
        .headers()
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or(ApiError::Unauthorized)?;

    // Parse "Basic <base64>" header
    let credentials = parse_basic_auth(auth_header).ok_or(ApiError::Unauthorized)?;

    if credentials.0 == state.config.admin_username
        && credentials.1 == state.config.admin_password
    {
        Ok(next.run(request).await)
    } else {
        Err(ApiError::Unauthorized)
    }
}

/// Parse `Authorization: Basic <base64(user:pass)>` header.
/// Returns `(username, password)` or `None` if malformed.
fn parse_basic_auth(header: &str) -> Option<(String, String)> {
    let encoded = header.strip_prefix("Basic ")?;
    let decoded = base64_decode(encoded)?;
    let s = std::str::from_utf8(&decoded).ok()?;
    let (user, pass) = s.split_once(':')?;
    Some((user.to_owned(), pass.to_owned()))
}

fn base64_decode(s: &str) -> Option<Vec<u8>> {
    use std::io::Read;
    // Use the base64 crate already in the dependency graph via sqlx/rustls
    // Decode standard base64 (with padding)
    let engine = base64::engine::general_purpose::STANDARD;
    base64::Engine::decode(&engine, s).ok()
}
```

Note: `base64` is already added to `Cargo.toml` in Phase 1 Task 4. It is also in the Bazel lockfile as `base64-0.22.1`. The `basic_auth.rs` source file uses it for production code (middleware), so Cargo's explicit dep declaration is required — transitive availability is not sufficient for direct `use base64::...` imports in production code.

**Verify + commit:**

```bash
cargo check 2>&1 | grep "error\[" | head -10
git add src/http/middleware/
git commit -m "feat: Basic auth middleware for admin routes"
```
<!-- END_TASK_2 -->

<!-- START_TASK_3 -->
### Task 3: Public API handlers

**Verifies:** rust-port.AC2.1–AC2.8

**Files:**
- Create: `src/http/events.rs`
- Create: `src/http/venues.rs`
- Create: `src/http/artists.rs`
- Create: `src/http/featured.rs`
- Create: `src/http/version.rs`

**Step 1: Create src/http/events.rs**

```rust
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
        dto::{EventDetailDto, EventDto, EventSourceDto, PageDto},
        error::ApiError,
        AppState,
    },
    ports::EventRepository,
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

fn default_per_page() -> i64 { 20 }

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
    let page = Pagination { page: q.page, per_page: q.per_page };
    let result = state.events.find_all(filters, page).await?;

    // Build EventDto for each event (venue detail not included in list — add Phase 4 extension)
    let items = result.items.iter().map(|e| EventDto {
        id: e.id.0,
        title: e.title.clone(),
        slug: e.slug.clone(),
        start_time: e.start_time,
        doors_time: e.doors_time,
        venue: None, // Populated below with venue lookup
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
    }).collect();

    Ok(Json(PageDto {
        items,
        total: result.total,
        page: result.page,
        per_page: result.per_page,
    }))
}

pub async fn get_event(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<EventDetailDto>, ApiError> {
    use crate::domain::event::EventId;
    let event = state.events.find_by_id(EventId(id)).await?;
    let related = state.events.find_related_events(event.id, 7).await?;

    let event_dto = EventDto {
        id: event.id.0,
        title: event.title.clone(),
        slug: event.slug.clone(),
        start_time: event.start_time,
        doors_time: event.doors_time,
        venue: None, // TODO: load venue in Phase 4 enhancement
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

    let related_dtos = related.iter().map(|e| EventDto {
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
    }).collect();

    Ok(Json(EventDetailDto {
        event: event_dto,
        description: event.description,
        end_time: event.end_time,
        sources: vec![], // TODO: load event_sources
        related_events: related_dtos,
    }))
}
```

Note: The venue and artist lookups are simplified above (returning `None`/empty). To fully satisfy AC2.3 (venue object, artist list in event detail), expand each handler to call `state.venues.find_by_id(event.venue_id)` and query `event_artists` for each event. This is acceptable complexity for Phase 4 to implement completely — do it inline rather than deferring it. Use `Option` gracefully: if venue lookup fails with `NotFound`, use `None` rather than propagating as error.

**Step 2: Create src/http/venues.rs**

```rust
use axum::{
    extract::{Path, Query, State},
    Json,
};
use serde::Deserialize;
use uuid::Uuid;

use crate::{
    domain::Pagination,
    http::{dto::{PageDto, VenueDto}, error::ApiError, AppState},
    ports::{EventRepository, VenueRepository},
};

#[derive(Deserialize, Default)]
pub struct VenuesQuery {
    pub neighborhood: Option<String>,
    #[serde(default)]
    pub page: i64,
    #[serde(default = "default_per_page")]
    pub per_page: i64,
}

fn default_per_page() -> i64 { 20 }

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
        let page = state.venues.find_all(Pagination { page: q.page, per_page: q.per_page }).await?;
        let total = page.total;
        (page.items, total)
    };

    // Get upcoming event counts per venue
    let counts = state.events.count_upcoming_by_venue().await?;
    let count_map: std::collections::HashMap<_, _> = counts.into_iter().collect();

    let dtos = items.iter().map(|v| VenueDto {
        id: v.id.0,
        name: v.effective_name().to_owned(),
        slug: v.effective_slug().to_owned(),
        neighborhood: v.neighborhood.clone(),
        website_url: v.website_url.clone(),
        upcoming_event_count: count_map.get(&v.id).copied().unwrap_or(0),
    }).collect();

    Ok(Json(PageDto { items: dtos, total, page: q.page, per_page: q.per_page }))
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
```

**Step 3: Create src/http/artists.rs**

```rust
use axum::{
    extract::{Path, Query, State},
    Json,
};
use serde::Deserialize;
use uuid::Uuid;

use crate::{
    domain::Pagination,
    http::{dto::{ArtistDto, PageDto}, error::ApiError, AppState},
    ports::ArtistRepository,
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

fn default_per_page() -> i64 { 20 }

pub async fn list_artists(
    State(state): State<AppState>,
    Query(q): Query<ArtistsQuery>,
) -> Result<Json<PageDto<ArtistDto>>, ApiError> {
    if q.local {
        let artists = state.artists.find_local().await?;
        let count = artists.len() as i64;
        let dtos = artists.iter().map(ArtistDto::from_artist).collect();
        return Ok(Json(PageDto { items: dtos, total: count, page: 0, per_page: count }));
    }
    if let Some(name) = &q.name {
        let artist = state.artists.find_by_name(name).await?;
        let items = artist.iter().map(ArtistDto::from_artist).collect::<Vec<_>>();
        let count = items.len() as i64;
        return Ok(Json(PageDto { items, total: count, page: 0, per_page: count }));
    }
    let page = state.artists.find_all(Pagination { page: q.page, per_page: q.per_page }).await?;
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
```

**Step 4: Create src/http/featured.rs**

```rust
use axum::{extract::State, Json};

use crate::{
    http::{dto::FeaturedEventDto, error::ApiError, AppState},
    ports::FeaturedEventRepository,
};

pub async fn get_featured(
    State(state): State<AppState>,
) -> Result<Json<FeaturedEventDto>, ApiError> {
    let featured = state.featured.find_current().await?
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
```

**Step 5: Create src/http/version.rs**

```rust
use axum::Json;
use serde_json::{json, Value};

pub async fn get_version() -> Json<Value> {
    Json(json!({
        "version": env!("CARGO_PKG_VERSION"),
        "build": "unknown",
        "commit": "unknown"
    }))
}
```

**Verify + commit:**

```bash
cargo check 2>&1 | grep "error\[" | head -20
git add src/http/
git commit -m "feat: public API handlers — events, venues, artists, featured, version"
```
<!-- END_TASK_3 -->

<!-- END_SUBCOMPONENT_A -->

<!-- START_SUBCOMPONENT_B (tasks 4-5) -->

<!-- START_TASK_4 -->
### Task 4: Admin handlers

**Verifies:** rust-port.AC5.1–AC5.7

**Files:**
- Create: `src/http/admin.rs`

```rust
//! Admin API handlers. All routes require HTTP Basic auth (enforced by middleware).

use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde::Deserialize;
use serde_json::json;
use uuid::Uuid;

use crate::{
    domain::{
        featured_event::{FeaturedEvent, FeaturedEventId},
        ingestion_run::IngestionRunRepository,
    },
    http::{
        dto::{FeaturedEventDto, IngestionRunDto, SourceHealthDto},
        error::ApiError,
        AppState,
    },
    ports::{FeaturedEventRepository, IngestionRunRepository as _, SourceRepository},
};

pub async fn list_sources(
    State(state): State<AppState>,
) -> Result<Json<Vec<SourceHealthDto>>, ApiError> {
    let sources = state.sources.find_all().await?;
    Ok(Json(sources.iter().map(SourceHealthDto::from_source).collect()))
}

pub async fn get_source_history(
    State(state): State<AppState>,
    Path(source_id): Path<Uuid>,
) -> Result<Json<Vec<IngestionRunDto>>, ApiError> {
    use crate::domain::source::SourceId;
    let runs = state.ingestion_runs.find_by_source_id_desc(SourceId(source_id)).await?;
    Ok(Json(runs.iter().map(IngestionRunDto::from_run).collect()))
}

pub async fn trigger_all_ingestion(
    State(state): State<AppState>,
) -> Result<Json<serde_json::Value>, ApiError> {
    if !state.config.ingestion_enabled {
        return Err(ApiError::Ingestion(
            crate::domain::error::IngestionError::Disabled,
        ));
    }
    // Actual ingestion dispatch happens in Phase 5. For now return a placeholder.
    Ok(Json(json!({
        "status": "triggered",
        "message": "Ingestion triggered. Results will be available in ingestion_runs."
    })))
}

pub async fn trigger_source_ingestion(
    State(state): State<AppState>,
    Path(source_id): Path<String>,
) -> Result<Json<serde_json::Value>, ApiError> {
    if !state.config.ingestion_enabled {
        return Err(ApiError::Ingestion(
            crate::domain::error::IngestionError::Disabled,
        ));
    }
    Ok(Json(json!({
        "status": "triggered",
        "source_id": source_id
    })))
}

pub async fn get_featured_history(
    State(state): State<AppState>,
) -> Result<Json<Vec<FeaturedEventDto>>, ApiError> {
    let featured_list = state.featured.find_all_desc().await?;
    let mut dtos = Vec::with_capacity(featured_list.len());
    for f in &featured_list {
        let event = state.events.find_by_id(f.event_id).await?;
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
        dtos.push(FeaturedEventDto {
            id: f.id.0,
            event: EventDetailDto {
                event: event_dto,
                description: event.description,
                end_time: event.end_time,
                sources: vec![],
                related_events: vec![],
            },
            blurb: f.blurb.clone(),
            created_at: f.created_at,
            created_by: f.created_by.clone(),
        });
    }
    Ok(Json(dtos))
}

#[derive(Deserialize)]
pub struct CreateFeaturedRequest {
    pub event_id: Uuid,
    pub blurb: String,
}

pub async fn create_featured(
    State(state): State<AppState>,
    Json(body): Json<CreateFeaturedRequest>,
) -> Result<(StatusCode, Json<FeaturedEventDto>), ApiError> {
    if body.blurb.trim().is_empty() {
        return Err(ApiError::BadRequest("blurb cannot be blank".to_owned()));
    }

    use crate::domain::event::EventId;
    // Verify the event exists — returns 404 if not
    let event = state.events.find_by_id(EventId(body.event_id)).await?;

    let featured = FeaturedEvent {
        id: FeaturedEventId::new(),
        event_id: event.id,
        blurb: body.blurb.trim().to_owned(),
        created_at: time::OffsetDateTime::now_utc(),
        created_by: "admin".to_owned(),
    };

    let saved = state.featured.save(&featured).await?;

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

    Ok((
        StatusCode::CREATED,
        Json(FeaturedEventDto {
            id: saved.id.0,
            event: EventDetailDto {
                event: event_dto,
                description: event.description,
                end_time: event.end_time,
                sources: vec![],
                related_events: vec![],
            },
            blurb: saved.blurb,
            created_at: saved.created_at,
            created_by: saved.created_by,
        }),
    ))
}
```

**Verify + commit:**

```bash
cargo check 2>&1 | grep "error\[" | head -20
git add src/http/admin.rs
git commit -m "feat: admin API handlers — sources, ingestion trigger, featured management"
```
<!-- END_TASK_4 -->

<!-- START_TASK_5 -->
### Task 5: Wire all routes in src/http/mod.rs

**Verifies:** All routes accessible at correct URL paths

**Files:**
- Modify: `src/http/mod.rs`

Read the file. Replace the `router()` function with the full route tree including the protected admin sub-router.

```rust
use axum::{middleware, routing::{get, post}, Router};
use tower_http::trace::TraceLayer;

pub mod admin;
pub mod artists;
pub mod dto;
pub mod error;
pub mod events;
pub mod featured;
pub mod middleware as http_middleware;
pub mod venues;
pub mod version;

pub use error::ApiError;

use crate::{config::Config, ports::*};
use std::sync::Arc;

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

pub fn create_router(state: AppState) -> Router {
    // Admin sub-router — protected by Basic auth middleware
    let admin_router = Router::new()
        .route("/api/admin/sources", get(admin::list_sources))
        .route("/api/admin/sources/{id}/history", get(admin::get_source_history))
        .route("/api/admin/ingest/trigger", post(admin::trigger_all_ingestion))
        .route("/api/admin/ingest/trigger/{source_id}", post(admin::trigger_source_ingestion))
        .route("/api/admin/featured/history", get(admin::get_featured_history))
        .route("/api/admin/featured", post(admin::create_featured))
        .route_layer(middleware::from_fn_with_state(
            state.clone(),
            http_middleware::basic_auth::require_basic_auth,
        ));

    // Public router
    let public_router = Router::new()
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

// --- Static asset handlers (unchanged from scaffold) ---
async fn index() -> impl axum::response::IntoResponse {
    // Serve the embedded frontend
    // (implementation is already in the scaffold from rust-embed)
    todo!("Implement embedded asset serving")
}

async fn asset(
    axum::extract::Path(path): axum::extract::Path<String>,
) -> impl axum::response::IntoResponse {
    todo!("Implement embedded asset serving: {path}")
}
```

Note on static asset serving: The existing scaffold already has embedded asset serving via `rust-embed`. Do NOT change that implementation — just preserve it from the current `mod.rs` and keep the `index` and `asset` handlers as-is.

**Verify:**

```bash
cargo check 2>&1 | grep "error\[" | head -20
```

**Commit:** `feat: full route tree wired — public API + admin sub-router with Basic auth`
<!-- END_TASK_5 -->

<!-- END_SUBCOMPONENT_B -->

<!-- START_TASK_6 -->
### Task 6: Handler tests

**Verifies:** rust-port.AC5.4, rust-port.AC5.5, rust-port.AC2.7, rust-port.AC2.8

**Files:**
- Modify: `tests/api.rs`
- Modify: `tests/support/mod.rs` (add fake implementations for testing)

**Step 1: Add fake repositories to tests/support/mod.rs**

Minimal in-memory fakes needed for Phase 4 handler tests. Add to `tests/support/mod.rs`:

```rust
//! Test support — fake adapters for unit testing HTTP handlers.

use async_trait::async_trait;
use districtlive_server::{
    domain::{
        artist::{Artist, ArtistId},
        error::RepoError,
        event::{Event, EventFilters, EventId, EventUpsertCommand},
        featured_event::{FeaturedEvent, FeaturedEventId},
        ingestion_run::{IngestionRun, IngestionRunId},
        source::{Source, SourceId},
        venue::{Venue, VenueId},
        Page, Pagination,
    },
    ports::{
        event_repository::UpsertResult, ArtistRepository, EventRepository,
        FeaturedEventRepository, IngestionRunRepository, SourceRepository, VenueRepository,
    },
};

/// Always-empty source repository for testing.
pub struct EmptySourceRepository;

#[async_trait]
impl SourceRepository for EmptySourceRepository {
    async fn find_by_id(&self, _id: SourceId) -> Result<Source, RepoError> { Err(RepoError::NotFound) }
    async fn find_by_name(&self, _name: &str) -> Result<Option<Source>, RepoError> { Ok(None) }
    async fn find_all(&self) -> Result<Vec<Source>, RepoError> { Ok(vec![]) }
    async fn find_healthy(&self) -> Result<Vec<Source>, RepoError> { Ok(vec![]) }
    async fn record_success(&self, _id: SourceId) -> Result<(), RepoError> { Ok(()) }
    async fn record_failure(&self, _id: SourceId, _msg: &str) -> Result<(), RepoError> { Ok(()) }
}

/// Always-empty event repository for testing.
pub struct EmptyEventRepository;

#[async_trait]
impl EventRepository for EmptyEventRepository {
    async fn upsert(&self, _cmd: EventUpsertCommand) -> Result<UpsertResult, RepoError> { Ok(UpsertResult::Created) }
    async fn find_by_id(&self, _id: EventId) -> Result<Event, RepoError> { Err(RepoError::NotFound) }
    async fn find_by_slug(&self, _slug: &str) -> Result<Option<Event>, RepoError> { Ok(None) }
    async fn find_all(&self, _f: EventFilters, _p: Pagination) -> Result<Page<Event>, RepoError> {
        Ok(Page { items: vec![], total: 0, page: 0, per_page: 20 })
    }
    async fn find_by_venue_id(&self, _id: VenueId) -> Result<Vec<Event>, RepoError> { Ok(vec![]) }
    async fn find_related_events(&self, _id: EventId, _days: i64) -> Result<Vec<Event>, RepoError> { Ok(vec![]) }
    async fn find_upcoming(&self) -> Result<Vec<Event>, RepoError> { Ok(vec![]) }
    async fn count_upcoming_by_venue(&self) -> Result<Vec<(VenueId, i64)>, RepoError> { Ok(vec![]) }
}

// Add EmptyVenueRepository, EmptyArtistRepository, EmptyFeaturedRepository, EmptyIngestionRunRepository
// following the same pattern as EmptyEventRepository above.

/// Construct a test AppState with empty repositories and test credentials.
pub fn test_state() -> districtlive_server::http::AppState {
    use std::sync::Arc;
    use districtlive_server::{config::Config, http::AppState};
    let config = Arc::new(Config {
        database_url: "unused".to_owned(),
        bind_addr: "0.0.0.0:0".parse().unwrap(),
        admin_username: "testuser".to_owned(),
        admin_password: "testpass".to_owned(),
        // Set all other fields to defaults for testing
        ..Default::default()
    });
    AppState {
        config,
        venues: Arc::new(EmptyVenueRepository),
        artists: Arc::new(EmptyArtistRepository),
        events: Arc::new(EmptyEventRepository),
        featured: Arc::new(EmptyFeaturedRepository),
        sources: Arc::new(EmptySourceRepository),
        ingestion_runs: Arc::new(EmptyIngestionRunRepository),
    }
}
```

Note: For `Config` to support `..Default::default()`, add `#[derive(Default)]` to `Config` in `src/config.rs` with sensible defaults (or add a `Config::test_default()` constructor method).

**Step 2: Update tests/api.rs**

```rust
use axum::http::StatusCode;
use axum_test::TestServer;

mod support;
use support::test_state;

fn test_server() -> TestServer {
    let app = districtlive_server::http::create_router(test_state());
    TestServer::new(app).expect("Failed to create test server")
}

#[tokio::test]
async fn healthz_returns_ok() {
    let server = test_server();
    server.get("/healthz").await.assert_status_ok();
}

// --- AC5.4: Missing Authorization header returns 401 ---
#[tokio::test]
async fn admin_without_auth_returns_401() {
    let server = test_server();
    server.get("/api/admin/sources").await.assert_status(StatusCode::UNAUTHORIZED);
}

// --- AC5.5: Wrong credentials return 401 ---
#[tokio::test]
async fn admin_wrong_credentials_returns_401() {
    let server = test_server();
    server
        .get("/api/admin/sources")
        .add_header("Authorization", "Basic d3Jvbmc6Y3JlZHM=") // wrong:creds in base64
        .await
        .assert_status(StatusCode::UNAUTHORIZED);
}

// --- AC5.1: Valid credentials return 200 ---
#[tokio::test]
async fn admin_valid_credentials_returns_200() {
    let server = test_server();
    // testuser:testpass in base64
    let creds = base64_encode("testuser:testpass");
    server
        .get("/api/admin/sources")
        .add_header("Authorization", &format!("Basic {creds}"))
        .await
        .assert_status_ok();
}

// --- AC2.7: Unknown event UUID returns 404 ---
#[tokio::test]
async fn get_event_unknown_id_returns_404() {
    let server = test_server();
    server
        .get("/api/events/00000000-0000-0000-0000-000000000001")
        .await
        .assert_status(StatusCode::NOT_FOUND);
}

// --- AC2.8: Malformed date_from returns 400 ---
#[tokio::test]
async fn list_events_bad_date_returns_400() {
    let server = test_server();
    server
        .get("/api/events?date_from=not-a-date")
        .await
        .assert_status(StatusCode::BAD_REQUEST);
}

fn base64_encode(s: &str) -> String {
    use base64::Engine;
    base64::engine::general_purpose::STANDARD.encode(s.as_bytes())
}
```

**Step 3: Update tests/BUILD.bazel :api target with base64 dep**

The test helper `base64_encode()` in `tests/api.rs` uses `base64::engine::general_purpose::STANDARD` directly. Per CLAUDE.md, test targets must explicitly list direct imports. Read `tests/BUILD.bazel` and find the `:api` test target. Add `@crates//:base64` to its deps:

```python
rust_test(
    name = "api",
    # ... existing fields ...
    deps = [
        "//:lib_with_test_helpers",
        "@crates//:axum-test",
        "@crates//:tokio",
        "@crates//:serde_json",
        "@crates//:base64",    # add this — tests/api.rs uses base64::engine directly
    ],
)
```

**Step 4: Update tests/support/mod.rs to use Config::test_default()**

The `test_state()` helper in `tests/support/mod.rs` needs a `Config` instance. Use the `Config::test_default()` function added to `src/config.rs` in Phase 1 (gated on `test-helpers` feature). The `test_state()` function becomes:

```rust
pub fn test_state() -> districtlive_server::http::AppState {
    use std::sync::Arc;
    use districtlive_server::{config::Config, http::AppState};
    let config = Arc::new(Config::test_default());
    AppState {
        config,
        venues: Arc::new(EmptyVenueRepository),
        artists: Arc::new(EmptyArtistRepository),
        events: Arc::new(EmptyEventRepository),
        featured: Arc::new(EmptyFeaturedRepository),
        sources: Arc::new(EmptySourceRepository),
        ingestion_runs: Arc::new(EmptyIngestionRunRepository),
        // Phase 5 fields (added later — add these stubs now to avoid breakage)
        ingestion_orchestrator: None,
        connectors: vec![],
    }
}
```

Note: The `ingestion_orchestrator` and `connectors` fields are added to AppState in Phase 5 Task 7. Adding them here as `None`/`vec![]` stubs prevents the Phase 4 test helper from breaking when Phase 5 expands AppState. If clippy warns about unused imports, add `#[cfg(feature = "test-helpers")]` guards.

**Step 5: Run tests**

```bash
just test
```

Expected: All 7 new tests pass.

**Commit:** `test: Phase 4 handler tests — auth middleware, 404, 400`
<!-- END_TASK_6 -->

<!-- START_TASK_7 -->
### Task 7: Final Phase 4 verification

**Step 1: Run full check**

```bash
just check
```

Expected: Passes. Fix any clippy warnings:
- Unused `ingestion_runs` import in admin.rs
- Dead code warnings on DTO fields
- Add `#[expect(dead_code)]` where needed or use `_` prefixes

**Step 2: Ensure all routes are accessible**

```bash
just test
```

Expected: All tests pass.

**Step 3: Verify Bazel build**

```bash
bazel build //... 2>&1 | tail -10
```

Expected: Successful build. If new crates are imported in `src/main.rs` directly, add them to `BUILD.bazel` `:app` deps.

**Commit:** `chore: phase 4 verification — just check and just test passing`
<!-- END_TASK_7 -->
