# DistrictLive Rust Port — Phase 2: Domain Types + Port Traits

**Goal:** Define all value types and port abstractions. No I/O. This phase is the type-checked specification of the entire domain — every subsequent phase builds on these types.

**Architecture:** Pure domain layer. `src/domain/` holds value types and error enums; `src/ports/` holds async traits. No database calls, HTTP calls, or I/O here. All port traits use `#[async_trait]` because they are stored as `Arc<dyn Trait>` in `AppState` (dynamic dispatch), which still requires the macro even on Rust 1.85.

**Tech Stack:** Rust 1.85, `uuid`, `time`, `rust_decimal`, `thiserror`, `async_trait`, `sqlx::Type` for enum/type mapping, `proptest` for invariant tests

**Scope:** Phase 2 of 7 from original design

**Codebase verified:** 2026-04-29

---

## Acceptance Criteria Coverage

Phase 2 produces foundational types. No AC is directly verified by tests here — this phase's correctness is demonstrated by compilation and the invariant property tests listed below. The ACs covered are those that depend on correct domain type definitions:

This phase creates the types needed for all subsequent ACs (AC1–AC7). Specifically it enables:
- `rust-port.AC1.2`: All expected tables' Rust representations exist as domain types
- All event, venue, artist, source, ingestion, enrichment types are defined correctly

**Test coverage in this phase:**
- Property tests for ID newtype equality and hashing
- Property tests for `Pagination` offset calculation invariants
- Enum variant round-trip tests (compile-time, not runtime DB tests)

---

## Prerequisite: Add rust_decimal feature to sqlx

Before writing domain types, update `Cargo.toml` to add `rust_decimal` to sqlx's feature list.

Read `/workspaces/districtlive-server/Cargo.toml`. Find the `sqlx` dependency and add `"rust_decimal"` to the features array:

```toml
sqlx = { version = "0.8", features = [
    "runtime-tokio-rustls",
    "postgres",
    "uuid",
    "time",
    "macros",
    "migrate",
    "rust_decimal",        # add this
] }
```

Run `cargo check` to confirm `rust_decimal` maps to NUMERIC columns. No `just bazel-repin` needed — sqlx is already in the lockfile; adding a feature doesn't add a new crate.

---

<!-- START_SUBCOMPONENT_A (tasks 1-3) -->

<!-- START_TASK_1 -->
### Task 1: Domain error types

**Verifies:** Foundational — all subsequent phases use these error types

**Files:**
- Create: `src/domain/error.rs`
- Modify: `src/domain/mod.rs` — add `pub mod error;` and re-export

**Step 1: Create src/domain/error.rs**

```rust
//! Domain error types shared across ports and adapters.

/// Errors returned by repository port implementations.
#[derive(Debug, thiserror::Error)]
pub enum RepoError {
    #[error("record not found")]
    NotFound,
    #[error("database error: {0}")]
    Database(#[from] sqlx::Error),
}

/// Errors returned by `SourceConnector::fetch` implementations.
#[derive(Debug, thiserror::Error)]
pub enum IngestionError {
    #[error("HTTP error fetching {url}: {source}")]
    Http {
        url: String,
        #[source]
        source: reqwest::Error,
    },
    #[error("parse error: {0}")]
    Parse(String),
    #[error("ingestion is disabled")]
    Disabled,
    #[error("database error: {0}")]
    Database(#[from] sqlx::Error),
    /// Wraps a repository error, enabling `?` from repo calls in the ingestion orchestrator.
    #[error("repository error: {0}")]
    Repo(#[from] RepoError),
}

/// Errors returned by `ArtistEnricher::enrich` implementations.
#[derive(Debug, thiserror::Error)]
pub enum EnrichmentError {
    #[error("HTTP error: {0}")]
    Http(#[from] reqwest::Error),
    #[error("rate limited by upstream API")]
    RateLimited,
    #[error("API error: {0}")]
    Api(String),
    #[error("enrichment is disabled")]
    Disabled,
}
```

Note: `reqwest::Error` in `IngestionError` and `EnrichmentError` is a forward reference — `reqwest` is not yet used in this phase, but these error types must compile. Verify `reqwest` is in `Cargo.toml` (added in Phase 1).

**Step 2: Update src/domain/mod.rs**

After `just clean-examples`, `src/domain/mod.rs` will be mostly empty (it had `MAX_GREET_NAME_LEN` and example blocks which are removed). Replace its contents with:

```rust
//! Domain types — pure value types with no I/O dependencies.

pub mod artist;
pub mod error;
pub mod event;
pub mod event_source;
pub mod featured_event;
pub mod ingestion_run;
pub mod source;
pub mod venue;

// Re-export error types at domain level for convenience
pub use error::{EnrichmentError, IngestionError, RepoError};

/// Generate a URL-safe slug from any string.
///
/// Lowercases input, replaces non-alphanumeric runs with a single hyphen,
/// and trims leading/trailing hyphens. Used by both ingestion normalization
/// (event slugs) and adapter code (venue/artist auto-creation slugs).
///
/// Single canonical implementation to ensure consistent slug formatting
/// across the entire application.
pub fn slugify(s: &str) -> String {
    let s = s.to_lowercase();
    let mut slug = String::with_capacity(s.len());
    let mut prev_hyphen = true;
    for c in s.chars() {
        if c.is_alphanumeric() {
            slug.push(c);
            prev_hyphen = false;
        } else if !prev_hyphen {
            slug.push('-');
            prev_hyphen = true;
        }
    }
    if slug.ends_with('-') {
        slug.pop();
    }
    slug
}

/// A paginated result set.
#[derive(Debug, Clone, serde::Serialize)]
pub struct Page<T> {
    pub items: Vec<T>,
    pub total: i64,
    pub page: i64,
    pub per_page: i64,
}

/// Pagination parameters passed to repository list methods.
#[derive(Debug, Clone, Copy)]
pub struct Pagination {
    /// Zero-based page index.
    pub page: i64,
    /// Number of items per page. Must be ≥ 1.
    pub per_page: i64,
}

impl Pagination {
    /// SQL OFFSET for this page.
    pub fn offset(self) -> i64 {
        self.page * self.per_page
    }
}

impl Default for Pagination {
    fn default() -> Self {
        Self { page: 0, per_page: 20 }
    }
}
```

**Step 3: Verify compilation**

```bash
cargo check 2>&1 | grep error || echo "Clean"
```

**Commit:** `feat: domain error types (RepoError, IngestionError, EnrichmentError)`
<!-- END_TASK_1 -->

<!-- START_TASK_2 -->
### Task 2: Core domain entities (Venue, Source, IngestionRun, FeaturedEvent)

**Verifies:** Provides types for rust-port.AC1.2 (table representations exist)

**Files:**
- Create: `src/domain/venue.rs`
- Create: `src/domain/source.rs`
- Create: `src/domain/ingestion_run.rs`
- Create: `src/domain/featured_event.rs`

**Step 1: Create src/domain/venue.rs**

```rust
//! Venue domain type — a physical venue where events take place.

use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

/// Newtype wrapper around UUID for venues. Prevents accidental ID confusion.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(transparent)]
pub struct VenueId(pub Uuid);

impl VenueId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for VenueId {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Display for VenueId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.0.fmt(f)
    }
}

#[derive(Debug, Clone, Serialize)]
pub struct Venue {
    pub id: VenueId,
    pub name: String,
    pub slug: String,
    pub address: Option<String>,
    pub neighborhood: Option<String>,
    pub capacity: Option<i32>,
    pub venue_type: Option<String>,
    pub website_url: Option<String>,
    /// Override for public display name (falls back to `name`).
    pub display_name: Option<String>,
    /// Override for public slug (falls back to `slug`).
    pub display_slug: Option<String>,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
}

impl Venue {
    /// The name shown publicly (display_name override or raw name).
    pub fn effective_name(&self) -> &str {
        self.display_name.as_deref().unwrap_or(&self.name)
    }

    /// The slug used in public URLs (display_slug override or raw slug).
    pub fn effective_slug(&self) -> &str {
        self.display_slug.as_deref().unwrap_or(&self.slug)
    }
}
```

**Step 2: Create src/domain/source.rs**

```rust
//! Source domain type — a configured data source (API or scraper).

use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(transparent)]
pub struct SourceId(pub Uuid);

impl SourceId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for SourceId {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Display for SourceId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.0.fmt(f)
    }
}

/// Classification of how this source retrieves events.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum SourceType {
    TicketmasterApi,
    BandsinTownApi,
    VenueScraper,
    Manual,
    DiceFm,
}

#[derive(Debug, Clone, Serialize)]
pub struct Source {
    pub id: SourceId,
    pub name: String,
    pub source_type: SourceType,
    /// Connector-specific config stored as JSONB in the DB (e.g., venue IDs, API keys).
    pub configuration: Option<serde_json::Value>,
    pub scrape_schedule: Option<String>,
    pub last_success_at: Option<OffsetDateTime>,
    pub last_failure_at: Option<OffsetDateTime>,
    pub consecutive_failures: i32,
    pub healthy: bool,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
}
```

**Step 3: Create src/domain/ingestion_run.rs**

```rust
//! IngestionRun domain type — a single execution record of the ingestion pipeline for one source.

use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::source::SourceId;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(transparent)]
pub struct IngestionRunId(pub Uuid);

impl IngestionRunId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for IngestionRunId {
    fn default() -> Self {
        Self::new()
    }
}

/// Lifecycle status of an ingestion run.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum IngestionRunStatus {
    Running,
    Success,
    Failed,
}

#[derive(Debug, Clone, Serialize)]
pub struct IngestionRun {
    pub id: IngestionRunId,
    pub source_id: SourceId,
    pub status: IngestionRunStatus,
    pub events_fetched: i32,
    pub events_created: i32,
    pub events_updated: i32,
    pub events_deduplicated: i32,
    pub error_message: Option<String>,
    pub started_at: OffsetDateTime,
    pub completed_at: Option<OffsetDateTime>,
}
```

**Step 4: Create src/domain/featured_event.rs**

```rust
//! FeaturedEvent domain type — a curated editorial pick for the homepage.

use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::event::EventId;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(transparent)]
pub struct FeaturedEventId(pub Uuid);

impl FeaturedEventId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for FeaturedEventId {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone, Serialize)]
pub struct FeaturedEvent {
    pub id: FeaturedEventId,
    pub event_id: EventId,
    pub blurb: String,
    pub created_at: OffsetDateTime,
    pub created_by: String,
}
```

**Step 5: Verify compilation**

```bash
cargo check 2>&1 | grep error || echo "Clean"
```

Expected: Clean (some dead_code warnings are acceptable at this stage).

**Commit:** `feat: venue, source, ingestion_run, featured_event domain types`
<!-- END_TASK_2 -->

<!-- START_TASK_3 -->
### Task 3: Artist domain type (includes enrichment types)

**Files:**
- Create: `src/domain/artist.rs`

```rust
//! Artist domain type and enrichment-related types.

use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(transparent)]
pub struct ArtistId(pub Uuid);

impl ArtistId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for ArtistId {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Display for ArtistId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.0.fmt(f)
    }
}

/// Lifecycle state of artist metadata enrichment.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum EnrichmentStatus {
    Pending,
    InProgress,
    Done,
    Failed,
    Skipped,
}

/// Which external service produced an enrichment result.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum EnrichmentSource {
    MusicBrainz,
    Spotify,
    Ollama,
}

/// The result produced by a successful `ArtistEnricher::enrich` call.
#[derive(Debug, Clone)]
pub struct EnrichmentResult {
    /// Which enrichment service produced this result.
    /// Included so the orchestrator can route fields without heuristics.
    pub source: EnrichmentSource,
    /// Canonical artist name as returned by the enrichment source.
    pub canonical_name: Option<String>,
    /// Source-specific ID (MBID for MusicBrainz, Spotify ID for Spotify).
    pub external_id: Option<String>,
    /// Genre/tag strings from the enrichment source.
    pub tags: Vec<String>,
    /// URL to artist image.
    pub image_url: Option<String>,
    /// Match confidence score 0.0–1.0.
    pub confidence: f64,
}

#[derive(Debug, Clone, Serialize)]
pub struct Artist {
    pub id: ArtistId,
    pub name: String,
    pub slug: String,
    pub genres: Vec<String>,
    pub is_local: bool,
    pub spotify_url: Option<String>,
    pub bandcamp_url: Option<String>,
    pub instagram_url: Option<String>,
    pub enrichment_status: EnrichmentStatus,
    pub enrichment_attempts: i32,
    pub last_enriched_at: Option<OffsetDateTime>,
    pub musicbrainz_id: Option<String>,
    pub spotify_id: Option<String>,
    pub canonical_name: Option<String>,
    pub mb_tags: Vec<String>,
    pub spotify_genres: Vec<String>,
    pub image_url: Option<String>,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
}
```

**Verify + commit:**

```bash
cargo check 2>&1 | grep error || echo "Clean"
git add src/domain/artist.rs
git commit -m "feat: artist domain type with EnrichmentStatus, EnrichmentSource, EnrichmentResult"
```
<!-- END_TASK_3 -->

<!-- END_SUBCOMPONENT_A -->

<!-- START_SUBCOMPONENT_B (tasks 4-5) -->

<!-- START_TASK_4 -->
### Task 4: Event and EventSource domain types (most complex)

**Files:**
- Create: `src/domain/event.rs`
- Create: `src/domain/event_source.rs`

**Step 1: Create src/domain/event.rs**

This file contains the Event entity, all event-related enums, the ingestion pipeline types, and the EventUpsertCommand.

```rust
//! Event domain types — the central entity of the system.
//!
//! Also contains ingestion pipeline types (RawEvent, NormalizedEvent,
//! DeduplicatedEvent, EventUpsertCommand) since they describe events
//! at different stages of processing.

use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::{event_source::SourceAttribution, venue::VenueId};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(transparent)]
pub struct EventId(pub Uuid);

impl EventId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for EventId {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Display for EventId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.0.fmt(f)
    }
}

/// Lifecycle status of an event listing.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum EventStatus {
    Active,
    Cancelled,
    Postponed,
    Rescheduled,
}

impl Default for EventStatus {
    fn default() -> Self {
        Self::Active
    }
}

/// Broad price tier for faceted filtering.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum PriceTier {
    Free,
    Under15,
    Price15To30,
    Over30,
}

/// Age restriction policy for the event.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum AgeRestriction {
    AllAges,
    EighteenPlus,
    TwentyOnePlus,
}

impl Default for AgeRestriction {
    fn default() -> Self {
        Self::AllAges
    }
}

/// Genre/format classification for an event.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum EventType {
    Concert,
    AlbumRelease,
    Showcase,
    Tribute,
    DjSet,
    Other,
}

#[derive(Debug, Clone, Serialize)]
pub struct Event {
    pub id: EventId,
    pub title: String,
    pub slug: String,
    pub description: Option<String>,
    pub start_time: OffsetDateTime,
    pub end_time: Option<OffsetDateTime>,
    pub doors_time: Option<OffsetDateTime>,
    pub min_price: Option<Decimal>,
    pub max_price: Option<Decimal>,
    pub price_tier: Option<PriceTier>,
    pub ticket_url: Option<String>,
    pub on_sale_date: Option<OffsetDateTime>,
    pub sold_out: bool,
    pub ticket_platform: Option<String>,
    pub image_url: Option<String>,
    pub age_restriction: AgeRestriction,
    pub status: EventStatus,
    pub venue_id: Option<VenueId>,
    pub title_parsed: bool,
    pub event_type: Option<EventType>,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
}

// ---------------------------------------------------------------------------
// Ingestion pipeline types
// ---------------------------------------------------------------------------

/// Unprocessed event data as returned directly by a `SourceConnector::fetch()` call.
/// Fields are as-received from the external source — no normalization applied.
#[derive(Debug, Clone)]
pub struct RawEvent {
    pub source_type: crate::domain::source::SourceType,
    pub source_identifier: Option<String>,
    pub source_url: Option<String>,
    pub title: String,
    pub description: Option<String>,
    pub venue_name: String,
    pub venue_address: Option<String>,
    pub artist_names: Vec<String>,
    pub start_time: OffsetDateTime,
    pub end_time: Option<OffsetDateTime>,
    pub doors_time: Option<OffsetDateTime>,
    pub min_price: Option<Decimal>,
    pub max_price: Option<Decimal>,
    pub ticket_url: Option<String>,
    pub image_url: Option<String>,
    pub age_restriction: Option<String>,
    pub genres: Vec<String>,
    pub confidence_score: Decimal,
}

/// A `RawEvent` after title cleaning, slug generation, and time normalization.
#[derive(Debug, Clone)]
pub struct NormalizedEvent {
    pub raw: RawEvent,
    /// URL-safe slug derived from title + venue_name + date (e.g. `the-national-9-30-club-2026-05-15`).
    pub slug: String,
}

/// One or more `NormalizedEvent`s that share the same slug, merged into a single record.
#[derive(Debug, Clone)]
pub struct DeduplicatedEvent {
    /// The canonical version of the event (first seen or highest-confidence).
    pub event: NormalizedEvent,
    /// All source attributions gathered from duplicate events with the same slug.
    pub sources: Vec<SourceAttribution>,
}

/// Command passed to `EventRepository::upsert` to create or update an event.
#[derive(Debug, Clone)]
pub struct EventUpsertCommand {
    pub slug: String,
    pub title: String,
    pub description: Option<String>,
    pub start_time: OffsetDateTime,
    pub end_time: Option<OffsetDateTime>,
    pub doors_time: Option<OffsetDateTime>,
    /// Venue name used to resolve or create the venue record.
    pub venue_name: String,
    pub venue_address: Option<String>,
    /// Artist names used to resolve or create artist records.
    pub artist_names: Vec<String>,
    pub min_price: Option<Decimal>,
    pub max_price: Option<Decimal>,
    pub price_tier: Option<PriceTier>,
    pub ticket_url: Option<String>,
    pub image_url: Option<String>,
    pub age_restriction: AgeRestriction,
    /// All source attributions to associate with this event.
    pub source_attributions: Vec<SourceAttribution>,
}

/// Filters passed to `EventRepository::find_all`.
#[derive(Debug, Clone, Default)]
pub struct EventFilters {
    pub date_from: Option<OffsetDateTime>,
    pub date_to: Option<OffsetDateTime>,
    pub venue_slug: Option<String>,
    pub genre: Option<String>,
    pub neighborhood: Option<String>,
    pub price_max: Option<Decimal>,
    pub status: Option<EventStatus>,
}
```

**Step 2: Create src/domain/event_source.rs**

```rust
//! EventSource domain type — records which external sources contributed to an event listing.

use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::{event::EventId, source::{SourceId, SourceType}};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(transparent)]
pub struct EventSourceId(pub Uuid);

impl EventSourceId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for EventSourceId {
    fn default() -> Self {
        Self::new()
    }
}

/// A record linking an event to one external source that reported it.
#[derive(Debug, Clone, Serialize)]
pub struct EventSource {
    pub id: EventSourceId,
    pub event_id: EventId,
    pub source_type: SourceType,
    pub source_identifier: Option<String>,
    pub source_url: Option<String>,
    pub last_scraped_at: Option<OffsetDateTime>,
    pub confidence_score: Decimal,
    pub created_at: OffsetDateTime,
    pub source_id: Option<SourceId>,
}

/// A single source attribution to attach to an `EventUpsertCommand`.
/// Describes which source reported an event during the ingestion pipeline.
#[derive(Debug, Clone)]
pub struct SourceAttribution {
    pub source_type: SourceType,
    pub source_identifier: Option<String>,
    pub source_url: Option<String>,
    pub confidence_score: Decimal,
    /// Resolved source ID (populated after looking up sources by name/type).
    pub source_id: Option<SourceId>,
}
```

**Step 3: Verify compilation**

```bash
cargo check 2>&1 | grep error || echo "Clean"
```

Fix any "unresolved import" errors — they indicate missing `use` statements. All domain types are pure data with no I/O.

**Commit:** `feat: event, event_source domain types + ingestion pipeline types`
<!-- END_TASK_4 -->

<!-- START_TASK_5 -->
### Task 5: Port traits (8 async trait files)

**Verifies:** Foundational — enables all subsequent phases

**Files:**
- Modify: `src/ports/mod.rs` — replace with new structure
- Create: `src/ports/venue_repository.rs`
- Create: `src/ports/artist_repository.rs`
- Create: `src/ports/event_repository.rs`
- Create: `src/ports/featured_event_repository.rs`
- Create: `src/ports/source_repository.rs`
- Create: `src/ports/ingestion_run_repository.rs`
- Create: `src/ports/source_connector.rs`
- Create: `src/ports/artist_enricher.rs`

**Note on async_trait:** All port traits use `#[async_trait]` because they are stored as `Arc<dyn Trait>` in `AppState`. Rust 1.85's native `async fn in trait` does not support dynamic dispatch (`Box<dyn Trait>` / `Arc<dyn Trait>`). The `async_trait` crate remains required for this use case.

**Step 1: Update src/ports/mod.rs**

```rust
//! Port traits — the interfaces between domain logic and infrastructure.
//!
//! Each trait is implemented by an adapter in `src/adapters/`.
//! All traits are object-safe (used as `Arc<dyn Trait>` in `AppState`),
//! which requires `#[async_trait]` for async methods.

pub mod artist_enricher;
pub mod artist_repository;
pub mod event_repository;
pub mod featured_event_repository;
pub mod ingestion_run_repository;
pub mod source_connector;
pub mod source_repository;
pub mod venue_repository;

pub use artist_enricher::ArtistEnricher;
pub use artist_repository::ArtistRepository;
pub use event_repository::EventRepository;
pub use featured_event_repository::FeaturedEventRepository;
pub use ingestion_run_repository::IngestionRunRepository;
pub use source_connector::SourceConnector;
pub use source_repository::SourceRepository;
pub use venue_repository::VenueRepository;
```

**Step 2: Create src/ports/venue_repository.rs**

```rust
use async_trait::async_trait;

use crate::domain::{
    error::RepoError,
    venue::{Venue, VenueId},
    Page, Pagination,
};

#[async_trait]
pub trait VenueRepository: Send + Sync {
    async fn find_by_id(&self, id: VenueId) -> Result<Venue, RepoError>;
    async fn find_by_slug(&self, slug: &str) -> Result<Venue, RepoError>;
    async fn find_by_name(&self, name: &str) -> Result<Option<Venue>, RepoError>;
    async fn find_by_neighborhood(&self, neighborhood: &str) -> Result<Vec<Venue>, RepoError>;
    async fn find_all(&self, page: Pagination) -> Result<Page<Venue>, RepoError>;
    async fn save(&self, venue: &Venue) -> Result<Venue, RepoError>;
}
```

**Step 3: Create src/ports/artist_repository.rs**

```rust
use async_trait::async_trait;

use crate::domain::{
    artist::{Artist, ArtistId},
    error::RepoError,
    Page, Pagination,
};

#[async_trait]
pub trait ArtistRepository: Send + Sync {
    async fn find_by_id(&self, id: ArtistId) -> Result<Artist, RepoError>;
    async fn find_by_slug(&self, slug: &str) -> Result<Option<Artist>, RepoError>;
    async fn find_by_name(&self, name: &str) -> Result<Option<Artist>, RepoError>;
    async fn find_all(&self, page: Pagination) -> Result<Page<Artist>, RepoError>;
    async fn find_local(&self) -> Result<Vec<Artist>, RepoError>;
    async fn save(&self, artist: &Artist) -> Result<Artist, RepoError>;

    /// Atomically claim a batch of PENDING artists and mark them IN_PROGRESS.
    ///
    /// Uses `SELECT ... FOR UPDATE SKIP LOCKED` to safely distribute work
    /// across concurrent enrichment workers.
    async fn claim_pending_batch(&self, batch_size: i64) -> Result<Vec<Artist>, RepoError>;

    /// Reset any IN_PROGRESS artists to PENDING (called at startup to recover from crashes).
    async fn reset_in_progress_to_pending(&self) -> Result<u64, RepoError>;

    /// Reset FAILED artists that have not exceeded `max_attempts` back to PENDING.
    async fn reset_eligible_failed_to_pending(&self, max_attempts: i32) -> Result<u64, RepoError>;
}
```

**Step 4: Create src/ports/event_repository.rs**

```rust
use async_trait::async_trait;

use crate::domain::{
    error::RepoError,
    event::{Event, EventFilters, EventId, EventUpsertCommand},
    Page, Pagination,
};

/// Result of an upsert operation — whether the row was inserted or updated.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum UpsertResult {
    Created,
    Updated,
}

#[async_trait]
pub trait EventRepository: Send + Sync {
    /// Insert or update an event record.
    ///
    /// Resolves (or creates) the venue and artist records referenced by the command.
    /// Uses `INSERT ... ON CONFLICT (slug) DO UPDATE` for idempotent upsert.
    /// The `UpsertResult` is derived from PostgreSQL's `xmax` system column.
    async fn upsert(&self, cmd: EventUpsertCommand) -> Result<UpsertResult, RepoError>;

    async fn find_by_id(&self, id: EventId) -> Result<Event, RepoError>;
    async fn find_by_slug(&self, slug: &str) -> Result<Option<Event>, RepoError>;
    async fn find_all(
        &self,
        filters: EventFilters,
        page: Pagination,
    ) -> Result<Page<Event>, RepoError>;
    async fn find_by_venue_id(&self, venue_id: crate::domain::venue::VenueId) -> Result<Vec<Event>, RepoError>;

    /// Find upcoming events at the same venue within ±7 days of the given event.
    async fn find_related_events(
        &self,
        event_id: EventId,
        window_days: i64,
    ) -> Result<Vec<Event>, RepoError>;

    async fn find_upcoming(&self) -> Result<Vec<Event>, RepoError>;

    /// Count upcoming events per venue (used for VenueDto.upcomingEventCount).
    async fn count_upcoming_by_venue(
        &self,
    ) -> Result<Vec<(crate::domain::venue::VenueId, i64)>, RepoError>;
}
```

**Step 5: Create src/ports/featured_event_repository.rs**

```rust
use async_trait::async_trait;

use crate::domain::{
    error::RepoError,
    featured_event::{FeaturedEvent, FeaturedEventId},
};

#[async_trait]
pub trait FeaturedEventRepository: Send + Sync {
    async fn find_current(&self) -> Result<Option<FeaturedEvent>, RepoError>;
    async fn find_all_desc(&self) -> Result<Vec<FeaturedEvent>, RepoError>;
    async fn find_by_id(&self, id: FeaturedEventId) -> Result<FeaturedEvent, RepoError>;
    async fn save(&self, featured: &FeaturedEvent) -> Result<FeaturedEvent, RepoError>;
}
```

**Step 6: Create src/ports/source_repository.rs**

```rust
use async_trait::async_trait;

use crate::domain::{
    error::RepoError,
    source::{Source, SourceId},
};

#[async_trait]
pub trait SourceRepository: Send + Sync {
    async fn find_by_id(&self, id: SourceId) -> Result<Source, RepoError>;
    async fn find_by_name(&self, name: &str) -> Result<Option<Source>, RepoError>;
    async fn find_all(&self) -> Result<Vec<Source>, RepoError>;
    async fn find_healthy(&self) -> Result<Vec<Source>, RepoError>;
    async fn record_success(&self, id: SourceId) -> Result<(), RepoError>;
    async fn record_failure(&self, id: SourceId, error_msg: &str) -> Result<(), RepoError>;
}
```

**Step 7: Create src/ports/ingestion_run_repository.rs**

```rust
use async_trait::async_trait;
use time::OffsetDateTime;

use crate::domain::{
    error::RepoError,
    ingestion_run::{IngestionRun, IngestionRunId},
    source::SourceId,
};

#[async_trait]
pub trait IngestionRunRepository: Send + Sync {
    async fn create(&self, source_id: SourceId) -> Result<IngestionRun, RepoError>;
    async fn mark_success(
        &self,
        id: IngestionRunId,
        events_fetched: i32,
        events_created: i32,
        events_updated: i32,
        events_deduplicated: i32,
    ) -> Result<(), RepoError>;
    async fn mark_failed(&self, id: IngestionRunId, error_message: &str) -> Result<(), RepoError>;
    async fn find_by_source_id_desc(&self, source_id: SourceId) -> Result<Vec<IngestionRun>, RepoError>;
}
```

**Step 8: Create src/ports/source_connector.rs**

```rust
use async_trait::async_trait;

use crate::domain::{
    error::IngestionError,
    event::RawEvent,
    source::SourceType,
};

#[async_trait]
pub trait SourceConnector: Send + Sync {
    /// Stable identifier for this connector matching the `sources.name` DB column.
    fn source_id(&self) -> &str;

    fn source_type(&self) -> SourceType;

    /// Fetch current events from the external source.
    async fn fetch(&self) -> Result<Vec<RawEvent>, IngestionError>;

    /// Returns `false` if the connector has a known configuration problem.
    fn health_check(&self) -> bool {
        true
    }
}
```

**Step 9: Create src/ports/artist_enricher.rs**

```rust
use async_trait::async_trait;

use crate::domain::{
    artist::{EnrichmentResult, EnrichmentSource},
    error::EnrichmentError,
};

#[async_trait]
pub trait ArtistEnricher: Send + Sync {
    /// Which enrichment service this adapter queries.
    fn source(&self) -> EnrichmentSource;

    /// Look up metadata for an artist by name.
    ///
    /// Returns `Ok(None)` if no match is found (not an error — just unknown artist).
    /// Returns `Err` only for transient failures (HTTP errors, rate limits).
    async fn enrich(
        &self,
        name: &str,
    ) -> Result<Option<EnrichmentResult>, EnrichmentError>;
}
```

**Step 10: Verify compilation**

```bash
cargo check 2>&1 | grep error || echo "Clean"
```

**Commit:** `feat: 8 port traits (venue, artist, event, featured, source, ingestion_run, connector, enricher)`
<!-- END_TASK_5 -->

<!-- END_SUBCOMPONENT_B -->

<!-- START_TASK_6 -->
### Task 6: Property tests for domain invariants

**Verifies:** Domain type correctness — ID equality, Pagination offset invariants

**Files:**
- Modify: `tests/properties.rs`

Read `tests/properties.rs`. After the clean-examples + greeter removal in Phase 1, this file should be mostly empty. Add the following property tests:

```rust
//! Property-based tests for domain type invariants.

use districtlive_server::domain::{
    venue::VenueId,
    artist::ArtistId,
    event::EventId,
    Pagination,
};
use proptest::prelude::*;

proptest! {
    // --- ID newtype invariants ---

    /// Two VenueIds wrapping the same UUID must be equal.
    /// This verifies the PartialEq derive correctly delegates to the inner Uuid.
    #[test]
    fn venue_id_equality_reflexive(bytes in prop::array::uniform16(0u8..)) {
        let uuid = uuid::Uuid::from_bytes(bytes);
        let id_a = VenueId(uuid);
        let id_b = VenueId(uuid);
        prop_assert_eq!(id_a, id_b);
    }

    /// Two ArtistIds wrapping different UUIDs must not be equal.
    #[test]
    fn artist_id_inequality(
        bytes_a in prop::array::uniform16(0u8..),
        bytes_b in prop::array::uniform16(0u8..),
    ) {
        let uuid_a = uuid::Uuid::from_bytes(bytes_a);
        let uuid_b = uuid::Uuid::from_bytes(bytes_b);
        prop_assume!(uuid_a != uuid_b);
        prop_assert_ne!(ArtistId(uuid_a), ArtistId(uuid_b));
    }

    // --- Pagination invariants ---

    /// Offset must equal page * per_page for all valid pagination inputs.
    #[test]
    fn pagination_offset_calculation(page in 0i64..1000, per_page in 1i64..200) {
        let p = Pagination { page, per_page };
        prop_assert_eq!(p.offset(), page * per_page);
    }

    /// Offset must be non-negative for non-negative page and positive per_page.
    #[test]
    fn pagination_offset_non_negative(page in 0i64..1000, per_page in 1i64..200) {
        let p = Pagination { page, per_page };
        prop_assert!(p.offset() >= 0);
    }

    /// Default pagination has page=0 offset=0.
    #[test]
    fn pagination_default_offset_is_zero(_unused in 0u8..1) {
        let p = Pagination::default();
        prop_assert_eq!(p.offset(), 0);
    }
}
```

Add `uuid` to the test imports. Verify `uuid` is accessible from tests (it's already in `lib.rs`'s re-exports via domain types, or add `use uuid::Uuid;` in the test file with `uuid` available via the `[dependencies]` in `Cargo.toml`).

**Run tests:**

```bash
just test
```

Expected: All property tests pass.

**Commit:** `test: domain invariant property tests (ID equality, Pagination offset)`
<!-- END_TASK_6 -->

<!-- START_TASK_7 -->
### Task 7: Final Phase 2 verification

**Verifies:** Phase 2 Done condition — all domain types + port traits compile, tests pass

**Step 1: Run full check**

```bash
just check
```

Expected: `cargo fmt --check` passes, `cargo clippy -- -D warnings` passes.

Common clippy issues at this stage:
- `dead_code` on struct fields — acceptable during development. Add `#[expect(dead_code, reason = "used in Phase 3+")]` to affected types if clippy fails CI.
- `clippy::new_without_default` on ID types — suppress with `#[expect]` or add `Default` impls (already added in the domain types above).

**Step 2: Run tests**

```bash
just test
```

Expected: All tests pass, including the new property tests.

**Step 3: Confirm domain module structure**

```bash
find src/domain src/ports -name "*.rs" | sort
```

Expected output (12 files):
```
src/domain/artist.rs
src/domain/error.rs
src/domain/event.rs
src/domain/event_source.rs
src/domain/featured_event.rs
src/domain/ingestion_run.rs
src/domain/mod.rs
src/domain/source.rs
src/domain/venue.rs
src/ports/artist_enricher.rs
src/ports/artist_repository.rs
src/ports/event_repository.rs
src/ports/featured_event_repository.rs
src/ports/ingestion_run_repository.rs
src/ports/mod.rs
src/ports/source_connector.rs
src/ports/source_repository.rs
src/ports/venue_repository.rs
```

**Step 4: Add uuid dep to :properties Bazel target**

The property tests import `uuid::Uuid` directly. Per CLAUDE.md conventions, test targets must explicitly list direct imports. Read `tests/BUILD.bazel` and find the `:properties` target. Add `@crates//:uuid` to its `deps` list:

```python
rust_test(
    name = "properties",
    # ... existing fields ...
    deps = [
        "//:lib",
        "@crates//:proptest",
        "@crates//:uuid",    # add this — properties.rs uses uuid::Uuid directly
    ],
)
```

**Commit:** `chore: phase 2 verification — just check and just test passing`
<!-- END_TASK_7 -->
