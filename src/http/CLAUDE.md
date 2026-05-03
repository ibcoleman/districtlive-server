# HTTP Layer

Last verified: 2026-05-02

## Purpose
Thin Axum layer: routing, auth middleware, request extraction, and JSON response mapping.
No business logic — handlers delegate to port-backed adapters in `AppState`.

## Contracts
- **Exposes**: `create_router(AppState) -> axum::Router`, `AppState` struct
- **Guarantees**: Public endpoints require no auth. Admin endpoints (`/api/admin/*`) require HTTP Basic auth via `require_basic_auth` middleware. `Path<Uuid>` parameters return 400 on malformed UUID (before reaching the handler), 404 on not-found.
- **Expects**: All `AppState` fields are `Arc<dyn Port>` — injected at startup in `main.rs`.

## API Routes
| Method | Path | Auth | Handler |
|--------|------|------|---------|
| GET | `/healthz` | none | inline |
| GET | `/api/version` | none | version |
| GET | `/api/events` | none | events::list_events |
| GET | `/api/events/{id}` | none | events::get_event |
| GET | `/api/venues` | none | venues::list_venues |
| GET | `/api/venues/{id}` | none | venues::get_venue |
| GET | `/api/artists` | none | artists::list_artists |
| GET | `/api/artists/{id}` | none | artists::get_artist |
| GET | `/api/featured` | none | featured::get_featured |
| GET | `/api/admin/sources` | basic | admin::list_sources |
| GET | `/api/admin/sources/{id}/history` | basic | admin::get_source_history |
| POST | `/api/admin/ingest/trigger` | basic | admin::trigger_all_ingestion |
| POST | `/api/admin/ingest/trigger/{source_id}` | basic | admin::trigger_source_ingestion |
| GET | `/api/admin/featured/history` | basic | admin::get_featured_history |
| POST | `/api/admin/featured` | basic | admin::create_featured |
| GET | `/admin/ingestion` | none (client-side) | ingestion HTML page |
| GET | `/admin/featured` | none (client-side) | featured HTML page |
| GET | `/` | none | embedded index.html |
| GET | `/assets/{*path}` | none | embedded static assets |

## Dependencies
- **Uses**: All port traits via `AppState`, `src/http/dto.rs` for JSON shapes, `src/ingestion::IngestionOrchestrator`, `src/enrichment` indirectly via ArtistRepository
- **Used by**: `src/main.rs` only
- **Boundary**: No direct sqlx. No business logic. Handlers are extract → delegate → map.

## Key Decisions
- Basic auth uses non-constant-time comparison (accepted risk, documented in middleware). HTTPS assumed in production.
- Admin HTML pages (`/admin/ingestion`, `/admin/featured`) are served without server-side auth; credentials are handled client-side via sessionStorage.
- Frontend static assets are compiled into the binary via `rust-embed` from `frontend/dist/`.

## Invariants
- `EventDto::from_event()` is used at every event-to-DTO conversion site (no inline mapping).
- `EventSourceDto::from_event_source()` is the single conversion point for source attributions on `GET /api/events/{id}`.
- `ArtistDto` exposes `canonical_name` and `image_url` but not `enrichment_status`, `mb_tags`, or `spotify_genres`.
- Hydration errors: `Database` errors propagate; `NotFound` errors for related venue/artists/sources are swallowed (event returns with null venue / empty artists / empty sources).
- `EventDetailDto.sources` is populated via `EventRepository::find_sources_by_event_id()` — never left as a placeholder empty vec.

## Key Files
- `mod.rs` — router and AppState definition
- `dto.rs` — all JSON response types
- `admin.rs` — admin endpoints
- `middleware/basic_auth.rs` — auth middleware

## Gotchas
- `EventDetailDto` uses `#[serde(flatten)]` — this is intentional and safe because it is serialization-only (never deserialized). Do not add `serde_ignored` to this type.
- `frontend/dist/` must be built before `cargo build` for embedded assets to include latest frontend.
