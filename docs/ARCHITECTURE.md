# Architecture

DistrictLive is a DC-area live-music event platform. The Rust server follows **hexagonal architecture** (ports & adapters). The Flutter app is the mobile client.

> **Note:** This document describes the *current* architecture of the DistrictLive codebase. Some sections were originally written for the template project (Notes, GreetingPort) and have been updated to reflect the real domain (Events, Venues, Artists, Ingestion, Enrichment).

## Hexagonal Shape

```
                         ┌─────────────────────┐
                         │    HTTP Adapter     │
                         │   (Axum router)     │
                         └──────────┬──────────┘
                                    │
                     ┌──────────────┴──────────────┐
                     │                             │
          ┌──────────▼──────────┐        ┌─────────▼─────────┐
          │  Domain Services    │        │  AppState DI      │
          │  (business logic)   │        │  (Arc<dyn>)       │
          └──────────┬──────────┘        └───────────────────┘
                     │
          ┌──────────▼──────────┐
          │   Ports (traits)    │
          │  EventRepository    │
          │  VenueRepository    │
          │  ArtistRepository   │
          │  SourceConnector    │
          └──────────┬──────────┘
                     │
     ┌───────────────┴────────────────┐
     │                                │
┌────▼─────────────┐     ┌───────────▼────────────┐
│  PgEventRepo     │     │  Test Fakes            │
│  (Postgres)      │     │  (EmptyEventRepo,      │
│                  │     │   SeededEventRepo)     │
└──────────────────┘     └────────────────────────┘
```

The outer ring is infrastructure (adapters); the inner ring is business logic (domain + ports).

## Where Each Concern Lives

### `src/domain/`

**Value types with no I/O.** Pure data structures:

- `Event`, `Venue`, `Artist`, `Source`, `FeaturedEvent`, `IngestionRun` — core entities
- `EventId`, `VenueId`, `ArtistId` — newtype-wrapped UUIDs
- `EventFilters`, `Pagination`, `Page<T>` — query/filter types
- Enums: `EventStatus`, `PriceTier`, `AgeRestriction`, `EventType`, `SourceType`
- Ingestion pipeline types: `RawEvent`, `NormalizedEvent`, `DeduplicatedEvent`, `EventUpsertCommand`

Nothing in `domain/` imports `sqlx` or async code beyond derive macros.

### `src/ports/`

**Async trait abstractions:**

- `EventRepository` — CRUD + `find_all(filters, page)` + `find_related_events`
- `VenueRepository` — find by id/slug/name, list, save
- `ArtistRepository` — find by id/slug/name, list, local, batch claim for enrichment
- `FeaturedEventRepository` — `find_current`, history, save
- `SourceRepository` — source health tracking
- `SourceConnector` — ingestion connector interface (`fetch() → Vec<RawEvent>`)

### `src/adapters/`

**Concrete implementations:**

- `pg_events.rs`, `pg_venues.rs`, `pg_artists.rs` — PostgreSQL implementations
- `connectors/` — 10 ingestion connectors (Ticketmaster API, Bandsintown API, Dice.fm, venue scrapers)
- `enrichers/` — MusicBrainz + Spotify artist enrichment

### `src/http/`

**HTTP boundary:**

- `mod.rs` — Axum router, `AppState`, embedded frontend assets
- `dto.rs` — all JSON response types (camelCase serialization for Flutter compat)
- `events.rs`, `venues.rs`, `artists.rs`, `featured.rs` — public API handlers
- `admin.rs` — admin endpoints (Basic auth)
- `middleware/basic_auth.rs` — auth middleware

## API Contract (Flutter Compatibility)

The server produces JSON matching the original Kotlin/Spring Boot server's contract:

- **Field casing**: camelCase (`startTime`, `minPrice`, `ticketUrl`)
- **Pagination**: Spring `Page<T>` format (`content`, `number`, `size`, `totalElements`, `totalPages`, `first`, `last`, `empty`)
- **Price serialization**: JSON numbers via `rust_decimal` `serde-float` feature
- **Enum casing**: SCREAMING_SNAKE_CASE (`ALL_AGES`, `TICKETMASTER_API`, `DICE_FM`)
- **Sort**: allowlist-based SQL ORDER BY (`startTime` → `e.start_time`, `createdAt` → `e.created_at`)

## Flutter Client (`flutter/`)

Feature-first clean architecture:

- **State**: Riverpod (`@riverpod` generated providers)
- **Local DB**: Drift (SQLite) with staleness-based cache-first loading
- **Network**: Dio (LogInterceptor in debug mode only)
- **Models**: Freezed + `json_serializable` (generated code committed)
- **Nav**: go_router with `StatefulShellRoute.indexedStack`

## Build

- **Cargo** — primary build for development (`cargo build`, `cargo test`)
- **Bazel** — CI build (`bazel test //...`), wraps Cargo via `rules_rust`
- **Justfile** — task runner (`just check`, `just test`, `just build`)
- **Frontend** — TypeScript SPA built via Vite, embedded into binary via `rust-embed`

## Testing Seams

### Unit Tests (`cargo test --lib`)

Offline, deterministic. Include serialization assertions for API contract compliance.

### Integration Tests (`tests/api.rs`)

Uses `axum-test` with fake repos (`EmptyEventRepository`, `SeededEventRepository`) — no database needed.

### Database Integration Tests (`tests/integration_db.rs`)

Real PostgreSQL, requires `DATABASE_URL`. Marked `#[ignore]` + Bazel `manual` tag.
