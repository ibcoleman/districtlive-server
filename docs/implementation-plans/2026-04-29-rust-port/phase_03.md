# DistrictLive Rust Port — Phase 3: PostgreSQL Adapters

**Goal:** Implement all six database adapters. After this phase the full persistence layer is functional and integration-tested.

**Architecture:** Six concrete adapter structs each implementing one port trait from Phase 2. All share a single `Arc<PgPool>` created at startup. The `EventRepository::upsert` is the most complex — it resolves-or-creates venues and artists, does `INSERT ... ON CONFLICT (slug) DO UPDATE`, and uses PostgreSQL's `xmax` system column to distinguish Created vs Updated. Dynamic event filtering uses `sqlx::QueryBuilder`.

**Tech Stack:** sqlx 0.8, PostgreSQL, `sqlx::QueryBuilder` for dynamic WHERE, transactions via `pool.begin()`, `SELECT FOR UPDATE SKIP LOCKED` for concurrent enrichment batch claiming

**Scope:** Phase 3 of 7 from original design

**Codebase verified:** 2026-04-29

---

## Acceptance Criteria Coverage

### rust-port.AC1: DB schema and migrations
- **rust-port.AC1.1 Success:** All 21 migrations apply cleanly against a fresh PostgreSQL database via `just test-integration`
- **rust-port.AC1.2 Success:** All expected tables exist after migration: `users`, `venues`, `artists`, `events`, `event_artists`, `event_sources`, `sources`, `ingestion_runs`, `featured_events`
- **rust-port.AC1.3 Success:** Seed data migrations populate `venues` and `sources` tables with the expected DC venue and source records
- **rust-port.AC1.4 Edge:** Running migrations twice does not error — sqlx migration tracking prevents re-application

---

<!-- START_SUBCOMPONENT_A (tasks 1-2) -->

<!-- START_TASK_1 -->
### Task 1: Database connectivity + AppState wiring + stale .sqlx cleanup

**Verifies:** None (infrastructure)

**Files:**
- Create: `src/adapters/db.rs` — shared pool creation + migration runner
- Delete: `.sqlx/query-a624b34*.json`, `.sqlx/query-e0069e87*.json`, `.sqlx/query-ff9c57f7*.json` (stale notes example files)
- Modify: `src/adapters/mod.rs` — add new adapter modules
- Modify: `src/http/mod.rs` — add 6 `Arc<dyn Trait>` fields to AppState
- Modify: `src/main.rs` — connect pool, construct adapters, wire AppState

**Step 1: Delete stale .sqlx files**

```bash
rm -f .sqlx/query-*.json
```

These offline query cache files are from the notes example. After Phase 1 removes `pg_notes.rs`, they become stale. New files will be regenerated in Task 7 after all adapter queries are written.

**Step 2: Create src/adapters/db.rs**

```rust
//! Database connection pool creation and migration runner.

use sqlx::{postgres::PgPoolOptions, PgPool};

/// Create a PostgreSQL connection pool and run pending migrations.
///
/// Call once at application startup. Pass the returned pool to each adapter constructor.
pub async fn connect(database_url: &str) -> anyhow::Result<PgPool> {
    let pool = PgPoolOptions::new()
        .max_connections(8)
        .connect(database_url)
        .await
        .map_err(|e| anyhow::anyhow!("Failed to connect to database: {e}"))?;

    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .map_err(|e| anyhow::anyhow!("Failed to run migrations: {e}"))?;

    Ok(pool)
}
```

**Step 3: Update src/adapters/mod.rs**

Replace the contents with:

```rust
pub mod db;
pub mod pg_artists;
pub mod pg_events;
pub mod pg_featured;
pub mod pg_ingestion_runs;
pub mod pg_sources;
pub mod pg_venues;

pub use db::connect;
pub use pg_artists::PgArtistRepository;
pub use pg_events::PgEventRepository;
pub use pg_featured::PgFeaturedEventRepository;
pub use pg_ingestion_runs::PgIngestionRunRepository;
pub use pg_sources::PgSourceRepository;
pub use pg_venues::PgVenueRepository;
```

**Step 4: Update AppState in src/http/mod.rs**

Read the file. Expand AppState with all six port trait objects:

```rust
use crate::{
    config::Config,
    ports::{
        ArtistRepository, EventRepository, FeaturedEventRepository,
        IngestionRunRepository, SourceRepository, VenueRepository,
    },
};
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
```

**Step 5: Update src/main.rs**

Read the file. Expand the startup sequence to connect to the database and wire all adapters:

```rust
use std::sync::Arc;
use districtlive_server::{
    adapters::{
        connect, PgArtistRepository, PgEventRepository, PgFeaturedEventRepository,
        PgIngestionRunRepository, PgSourceRepository, PgVenueRepository,
    },
    config::Config,
    http::{create_router, AppState},
};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // ... existing tracing init

    let config = Arc::new(Config::from_env()?);
    let pool = Arc::new(connect(&config.database_url).await?);

    let state = AppState {
        config: config.clone(),
        venues: Arc::new(PgVenueRepository::new(pool.clone())),
        artists: Arc::new(PgArtistRepository::new(pool.clone())),
        events: Arc::new(PgEventRepository::new(pool.clone())),
        featured: Arc::new(PgFeaturedEventRepository::new(pool.clone())),
        sources: Arc::new(PgSourceRepository::new(pool.clone())),
        ingestion_runs: Arc::new(PgIngestionRunRepository::new(pool.clone())),
    };

    let bind_addr = config.bind_addr;
    let app = create_router(state);
    let listener = tokio::net::TcpListener::bind(bind_addr).await?;
    // ... existing graceful shutdown
}
```

**Step 6: Verify compilation (expected to fail until adapters are created)**

```bash
cargo check 2>&1 | grep "unresolved\|cannot find" | head -20
```

Expected: Errors about missing `PgVenueRepository` etc — that's fine, they'll be created in Tasks 2–5. The imports and AppState struct must compile.

**Commit:** `chore: db connect/migrate, AppState with 6 port slots, delete stale .sqlx`
<!-- END_TASK_1 -->

<!-- START_TASK_2 -->
### Task 2: Simple adapters — venues, sources, ingestion_runs, featured_events

**Verifies:** rust-port.AC1.1–AC1.4 (via integration tests in Task 6)

**Files:**
- Create: `src/adapters/pg_venues.rs`
- Create: `src/adapters/pg_sources.rs`
- Create: `src/adapters/pg_ingestion_runs.rs`
- Create: `src/adapters/pg_featured.rs`

**Step 1: Create src/adapters/pg_venues.rs**

```rust
use async_trait::async_trait;
use sqlx::{PgPool, Row};
use std::sync::Arc;
use time::OffsetDateTime;

use crate::domain::{
    error::RepoError,
    venue::{Venue, VenueId},
    Page, Pagination,
};
use crate::ports::VenueRepository;

#[derive(Clone)]
pub struct PgVenueRepository {
    pool: Arc<PgPool>,
}

impl PgVenueRepository {
    pub fn new(pool: Arc<PgPool>) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl VenueRepository for PgVenueRepository {
    async fn find_by_id(&self, id: VenueId) -> Result<Venue, RepoError> {
        sqlx::query_as!(
            VenueRow,
            r#"SELECT id as "id: uuid::Uuid", name, slug, address, neighborhood,
                      capacity, venue_type, website_url, display_name, display_slug,
                      created_at, updated_at
               FROM venues WHERE id = $1"#,
            id.0
        )
        .fetch_optional(&*self.pool)
        .await?
        .map(Venue::from)
        .ok_or(RepoError::NotFound)
    }

    async fn find_by_slug(&self, slug: &str) -> Result<Venue, RepoError> {
        sqlx::query_as!(
            VenueRow,
            r#"SELECT id as "id: uuid::Uuid", name, slug, address, neighborhood,
                      capacity, venue_type, website_url, display_name, display_slug,
                      created_at, updated_at
               FROM venues WHERE slug = $1 OR display_slug = $1"#,
            slug
        )
        .fetch_optional(&*self.pool)
        .await?
        .map(Venue::from)
        .ok_or(RepoError::NotFound)
    }

    async fn find_by_name(&self, name: &str) -> Result<Option<Venue>, RepoError> {
        let row = sqlx::query_as!(
            VenueRow,
            r#"SELECT id as "id: uuid::Uuid", name, slug, address, neighborhood,
                      capacity, venue_type, website_url, display_name, display_slug,
                      created_at, updated_at
               FROM venues WHERE lower(name) = lower($1)"#,
            name
        )
        .fetch_optional(&*self.pool)
        .await?;
        Ok(row.map(Venue::from))
    }

    async fn find_by_neighborhood(&self, neighborhood: &str) -> Result<Vec<Venue>, RepoError> {
        let rows = sqlx::query_as!(
            VenueRow,
            r#"SELECT id as "id: uuid::Uuid", name, slug, address, neighborhood,
                      capacity, venue_type, website_url, display_name, display_slug,
                      created_at, updated_at
               FROM venues WHERE neighborhood = $1 ORDER BY name"#,
            neighborhood
        )
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(Venue::from).collect())
    }

    async fn find_all(&self, page: Pagination) -> Result<Page<Venue>, RepoError> {
        let total: i64 = sqlx::query_scalar!("SELECT COUNT(*) FROM venues")
            .fetch_one(&*self.pool)
            .await?
            .unwrap_or(0);

        let rows = sqlx::query_as!(
            VenueRow,
            r#"SELECT id as "id: uuid::Uuid", name, slug, address, neighborhood,
                      capacity, venue_type, website_url, display_name, display_slug,
                      created_at, updated_at
               FROM venues ORDER BY name
               LIMIT $1 OFFSET $2"#,
            page.per_page,
            page.offset()
        )
        .fetch_all(&*self.pool)
        .await?;

        Ok(Page {
            items: rows.into_iter().map(Venue::from).collect(),
            total,
            page: page.page,
            per_page: page.per_page,
        })
    }

    async fn save(&self, venue: &Venue) -> Result<Venue, RepoError> {
        sqlx::query!(
            r#"INSERT INTO venues (id, name, slug, address, neighborhood, capacity,
                                   venue_type, website_url, display_name, display_slug,
                                   created_at, updated_at)
               VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
               ON CONFLICT (id) DO UPDATE SET
                   name = EXCLUDED.name, slug = EXCLUDED.slug,
                   address = EXCLUDED.address, neighborhood = EXCLUDED.neighborhood,
                   display_name = EXCLUDED.display_name, display_slug = EXCLUDED.display_slug,
                   updated_at = now()"#,
            venue.id.0, &venue.name, &venue.slug, venue.address.as_deref(),
            venue.neighborhood.as_deref(), venue.capacity, venue.venue_type.as_deref(),
            venue.website_url.as_deref(), venue.display_name.as_deref(),
            venue.display_slug.as_deref(), venue.created_at, venue.updated_at
        )
        .execute(&*self.pool)
        .await?;
        self.find_by_id(venue.id).await
    }
}

// ---- Row type for sqlx deserialization ----

struct VenueRow {
    id: uuid::Uuid,
    name: String,
    slug: String,
    address: Option<String>,
    neighborhood: Option<String>,
    capacity: Option<i32>,
    venue_type: Option<String>,
    website_url: Option<String>,
    display_name: Option<String>,
    display_slug: Option<String>,
    created_at: OffsetDateTime,
    updated_at: OffsetDateTime,
}

impl From<VenueRow> for Venue {
    fn from(r: VenueRow) -> Self {
        Venue {
            id: VenueId(r.id),
            name: r.name,
            slug: r.slug,
            address: r.address,
            neighborhood: r.neighborhood,
            capacity: r.capacity,
            venue_type: r.venue_type,
            website_url: r.website_url,
            display_name: r.display_name,
            display_slug: r.display_slug,
            created_at: r.created_at,
            updated_at: r.updated_at,
        }
    }
}
```

**Step 2: Create src/adapters/pg_sources.rs**

Follow the same pattern as pg_venues.rs. Key methods:

- `find_by_id`, `find_by_name`, `find_all`, `find_healthy` — standard SELECT queries
- `record_success` — UPDATE to set `last_success_at = now(), consecutive_failures = 0, healthy = true`
- `record_failure` — UPDATE to increment `consecutive_failures` and set `healthy = false` when failures > 3

```rust
// Key SQL for record_success:
// UPDATE sources
// SET last_success_at = now(), consecutive_failures = 0, healthy = true, updated_at = now()
// WHERE id = $1

// Key SQL for record_failure:
// UPDATE sources
// SET last_failure_at = now(),
//     consecutive_failures = consecutive_failures + 1,
//     healthy = (consecutive_failures + 1) <= 3,
//     updated_at = now()
// WHERE id = $1
```

Use a `SourceRow` struct (same pattern as `VenueRow`) and `impl From<SourceRow> for Source`.

For `SourceType` enum mapping, use `sqlx::query!` with `source_type as "source_type: SourceType"` in the SELECT to tell sqlx the Rust type:

```rust
sqlx::query!(
    r#"SELECT id as "id: uuid::Uuid", name,
              source_type as "source_type: crate::domain::source::SourceType",
              ...
       FROM sources WHERE id = $1"#,
    id.0
)
```

**Step 3: Create src/adapters/pg_ingestion_runs.rs**

Key SQL:

```sql
-- create:
INSERT INTO ingestion_runs (id, source_id, status, started_at)
VALUES ($1, $2, 'RUNNING', now())
RETURNING *

-- mark_success:
UPDATE ingestion_runs
SET status = 'SUCCESS', events_fetched = $2, events_created = $3,
    events_updated = $4, events_deduplicated = $5, completed_at = now()
WHERE id = $1

-- mark_failed:
UPDATE ingestion_runs
SET status = 'FAILED', error_message = $2, completed_at = now()
WHERE id = $1

-- find_by_source_id_desc:
SELECT * FROM ingestion_runs
WHERE source_id = $1
ORDER BY started_at DESC
```

**Step 4: Create src/adapters/pg_featured.rs**

Key SQL:

```sql
-- find_current (most recently created featured event):
SELECT * FROM featured_events
ORDER BY created_at DESC
LIMIT 1

-- find_all_desc:
SELECT * FROM featured_events ORDER BY created_at DESC

-- save (INSERT + RETURNING for fresh fetch):
INSERT INTO featured_events (id, event_id, blurb, created_at, created_by)
VALUES ($1, $2, $3, now(), $4)
RETURNING *
```

**Step 5: Verify compilation**

```bash
cargo check 2>&1 | grep "error\[" | head -20
```

Expected: Only errors about `PgArtistRepository` and `PgEventRepository` still missing.

**Commit:** `feat: pg_venues, pg_sources, pg_ingestion_runs, pg_featured adapters`
<!-- END_TASK_2 -->

<!-- END_SUBCOMPONENT_A -->

<!-- START_SUBCOMPONENT_B (tasks 3-5) -->

<!-- START_TASK_3 -->
### Task 3: Artist adapter (claim_pending_batch + enrichment state transitions)

**Verifies:** rust-port.AC4.3 (orphan reset at startup)

**Files:**
- Create: `src/adapters/pg_artists.rs`

The artist adapter has two complex methods beyond standard CRUD:
1. `claim_pending_batch` — atomic SELECT FOR UPDATE SKIP LOCKED + UPDATE in a transaction
2. `reset_in_progress_to_pending` — bulk UPDATE for crash recovery

**Create src/adapters/pg_artists.rs:**

```rust
use async_trait::async_trait;
use sqlx::PgPool;
use std::sync::Arc;
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::{
    artist::{Artist, ArtistId, EnrichmentStatus},
    error::RepoError,
    Page, Pagination,
};
use crate::ports::ArtistRepository;

#[derive(Clone)]
pub struct PgArtistRepository {
    pool: Arc<PgPool>,
}

impl PgArtistRepository {
    pub fn new(pool: Arc<PgPool>) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl ArtistRepository for PgArtistRepository {
    async fn find_by_id(&self, id: ArtistId) -> Result<Artist, RepoError> {
        sqlx::query_as!(
            ArtistRow,
            r#"SELECT id as "id: Uuid", name, slug, genres, is_local,
                      spotify_url, bandcamp_url, instagram_url,
                      enrichment_status as "enrichment_status: EnrichmentStatus",
                      enrichment_attempts, last_enriched_at, musicbrainz_id,
                      spotify_id, canonical_name, mb_tags, spotify_genres,
                      image_url, created_at, updated_at
               FROM artists WHERE id = $1"#,
            id.0
        )
        .fetch_optional(&*self.pool)
        .await?
        .map(Artist::from)
        .ok_or(RepoError::NotFound)
    }

    async fn find_by_slug(&self, slug: &str) -> Result<Option<Artist>, RepoError> {
        let row = sqlx::query_as!(
            ArtistRow,
            r#"SELECT id as "id: Uuid", name, slug, genres, is_local,
                      spotify_url, bandcamp_url, instagram_url,
                      enrichment_status as "enrichment_status: EnrichmentStatus",
                      enrichment_attempts, last_enriched_at, musicbrainz_id,
                      spotify_id, canonical_name, mb_tags, spotify_genres,
                      image_url, created_at, updated_at
               FROM artists WHERE slug = $1"#,
            slug
        )
        .fetch_optional(&*self.pool)
        .await?;
        Ok(row.map(Artist::from))
    }

    async fn find_by_name(&self, name: &str) -> Result<Option<Artist>, RepoError> {
        let row = sqlx::query_as!(
            ArtistRow,
            r#"SELECT id as "id: Uuid", name, slug, genres, is_local,
                      spotify_url, bandcamp_url, instagram_url,
                      enrichment_status as "enrichment_status: EnrichmentStatus",
                      enrichment_attempts, last_enriched_at, musicbrainz_id,
                      spotify_id, canonical_name, mb_tags, spotify_genres,
                      image_url, created_at, updated_at
               FROM artists WHERE lower(name) = lower($1)"#,
            name
        )
        .fetch_optional(&*self.pool)
        .await?;
        Ok(row.map(Artist::from))
    }

    async fn find_all(&self, page: Pagination) -> Result<Page<Artist>, RepoError> {
        let total: i64 = sqlx::query_scalar!("SELECT COUNT(*) FROM artists")
            .fetch_one(&*self.pool)
            .await?
            .unwrap_or(0);

        let rows = sqlx::query_as!(
            ArtistRow,
            r#"SELECT id as "id: Uuid", name, slug, genres, is_local,
                      spotify_url, bandcamp_url, instagram_url,
                      enrichment_status as "enrichment_status: EnrichmentStatus",
                      enrichment_attempts, last_enriched_at, musicbrainz_id,
                      spotify_id, canonical_name, mb_tags, spotify_genres,
                      image_url, created_at, updated_at
               FROM artists ORDER BY name
               LIMIT $1 OFFSET $2"#,
            page.per_page,
            page.offset()
        )
        .fetch_all(&*self.pool)
        .await?;

        Ok(Page {
            items: rows.into_iter().map(Artist::from).collect(),
            total,
            page: page.page,
            per_page: page.per_page,
        })
    }

    async fn find_local(&self) -> Result<Vec<Artist>, RepoError> {
        let rows = sqlx::query_as!(
            ArtistRow,
            r#"SELECT id as "id: Uuid", name, slug, genres, is_local,
                      spotify_url, bandcamp_url, instagram_url,
                      enrichment_status as "enrichment_status: EnrichmentStatus",
                      enrichment_attempts, last_enriched_at, musicbrainz_id,
                      spotify_id, canonical_name, mb_tags, spotify_genres,
                      image_url, created_at, updated_at
               FROM artists WHERE is_local = true ORDER BY name"#
        )
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(Artist::from).collect())
    }

    async fn save(&self, artist: &Artist) -> Result<Artist, RepoError> {
        sqlx::query!(
            r#"INSERT INTO artists (id, name, slug, genres, is_local,
                                    enrichment_status, enrichment_attempts,
                                    created_at, updated_at)
               VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
               ON CONFLICT (id) DO UPDATE SET
                   name = EXCLUDED.name,
                   enrichment_status = EXCLUDED.enrichment_status,
                   enrichment_attempts = EXCLUDED.enrichment_attempts,
                   canonical_name = EXCLUDED.canonical_name,
                   musicbrainz_id = EXCLUDED.musicbrainz_id,
                   spotify_id = EXCLUDED.spotify_id,
                   mb_tags = EXCLUDED.mb_tags,
                   spotify_genres = EXCLUDED.spotify_genres,
                   image_url = EXCLUDED.image_url,
                   last_enriched_at = EXCLUDED.last_enriched_at,
                   updated_at = now()"#,
            artist.id.0,
            &artist.name,
            &artist.slug,
            &artist.genres as &[String],
            artist.is_local,
            artist.enrichment_status as EnrichmentStatus,
            artist.enrichment_attempts,
            artist.created_at,
            artist.updated_at
        )
        .execute(&*self.pool)
        .await?;
        self.find_by_id(artist.id).await
    }

    async fn claim_pending_batch(&self, batch_size: i64) -> Result<Vec<Artist>, RepoError> {
        let mut tx = self.pool.begin().await?;

        // Step 1: Lock a batch of PENDING artists, skipping any locked by other workers.
        let ids: Vec<Uuid> = sqlx::query_scalar!(
            r#"SELECT id as "id: Uuid"
               FROM artists
               WHERE enrichment_status = 'PENDING'
               ORDER BY created_at ASC
               LIMIT $1
               FOR UPDATE SKIP LOCKED"#,
            batch_size
        )
        .fetch_all(&mut *tx)
        .await?;

        if ids.is_empty() {
            tx.rollback().await?;
            return Ok(vec![]);
        }

        // Step 2: Mark claimed artists as IN_PROGRESS atomically within the same transaction.
        sqlx::query!(
            "UPDATE artists SET enrichment_status = 'IN_PROGRESS', updated_at = now()
             WHERE id = ANY($1)",
            &ids as &[Uuid]
        )
        .execute(&mut *tx)
        .await?;

        // Step 3: Fetch full artist records before committing.
        let rows = sqlx::query_as!(
            ArtistRow,
            r#"SELECT id as "id: Uuid", name, slug, genres, is_local,
                      spotify_url, bandcamp_url, instagram_url,
                      enrichment_status as "enrichment_status: EnrichmentStatus",
                      enrichment_attempts, last_enriched_at, musicbrainz_id,
                      spotify_id, canonical_name, mb_tags, spotify_genres,
                      image_url, created_at, updated_at
               FROM artists WHERE id = ANY($1)"#,
            &ids as &[Uuid]
        )
        .fetch_all(&mut *tx)
        .await?;

        tx.commit().await?;
        Ok(rows.into_iter().map(Artist::from).collect())
    }

    async fn reset_in_progress_to_pending(&self) -> Result<u64, RepoError> {
        let result = sqlx::query!(
            "UPDATE artists SET enrichment_status = 'PENDING', updated_at = now()
             WHERE enrichment_status = 'IN_PROGRESS'"
        )
        .execute(&*self.pool)
        .await?;
        Ok(result.rows_affected())
    }

    async fn reset_eligible_failed_to_pending(&self, max_attempts: i32) -> Result<u64, RepoError> {
        let result = sqlx::query!(
            "UPDATE artists SET enrichment_status = 'PENDING', updated_at = now()
             WHERE enrichment_status = 'FAILED' AND enrichment_attempts < $1",
            max_attempts
        )
        .execute(&*self.pool)
        .await?;
        Ok(result.rows_affected())
    }
}

// ---- Row type ----

struct ArtistRow {
    id: Uuid,
    name: String,
    slug: String,
    genres: Vec<String>,
    is_local: bool,
    spotify_url: Option<String>,
    bandcamp_url: Option<String>,
    instagram_url: Option<String>,
    enrichment_status: EnrichmentStatus,
    enrichment_attempts: i32,
    last_enriched_at: Option<OffsetDateTime>,
    musicbrainz_id: Option<String>,
    spotify_id: Option<String>,
    canonical_name: Option<String>,
    mb_tags: Vec<String>,
    spotify_genres: Vec<String>,
    image_url: Option<String>,
    created_at: OffsetDateTime,
    updated_at: OffsetDateTime,
}

impl From<ArtistRow> for Artist {
    fn from(r: ArtistRow) -> Self {
        Artist {
            id: ArtistId(r.id),
            name: r.name,
            slug: r.slug,
            genres: r.genres,
            is_local: r.is_local,
            spotify_url: r.spotify_url,
            bandcamp_url: r.bandcamp_url,
            instagram_url: r.instagram_url,
            enrichment_status: r.enrichment_status,
            enrichment_attempts: r.enrichment_attempts,
            last_enriched_at: r.last_enriched_at,
            musicbrainz_id: r.musicbrainz_id,
            spotify_id: r.spotify_id,
            canonical_name: r.canonical_name,
            mb_tags: r.mb_tags,
            spotify_genres: r.spotify_genres,
            image_url: r.image_url,
            created_at: r.created_at,
            updated_at: r.updated_at,
        }
    }
}
```

**Verify + commit:**

```bash
cargo check 2>&1 | grep "error\[" | head -10
git add src/adapters/pg_artists.rs
git commit -m "feat: pg_artists adapter with SKIP LOCKED claim_pending_batch"
```
<!-- END_TASK_3 -->

<!-- START_TASK_4 -->
### Task 4: Event adapter (upsert + dynamic filters + xmax)

**Files:**
- Create: `src/adapters/pg_events.rs`

This is the most complex adapter. The `upsert` method runs in a transaction and:
1. Resolves or creates the venue by name
2. Resolves or creates each artist by name (with generated slug)
3. Upserts the event using `ON CONFLICT (slug) DO UPDATE` with `xmax` detection
4. Inserts `event_artists` join rows
5. Upserts `event_sources` records

The `find_all` method uses `sqlx::QueryBuilder` for dynamic WHERE clauses.

**Create src/adapters/pg_events.rs:**

```rust
use async_trait::async_trait;
use rust_decimal::Decimal;
use sqlx::{PgPool, QueryBuilder, Row};
use std::sync::Arc;
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::{
    error::RepoError,
    event::{
        AgeRestriction, Event, EventFilters, EventId, EventStatus, EventType, EventUpsertCommand,
        PriceTier, RawEvent,
    },
    event_source::EventSourceId,
    venue::VenueId,
    Page, Pagination,
};
use crate::ports::{
    event_repository::UpsertResult,
    EventRepository,
};

#[derive(Clone)]
pub struct PgEventRepository {
    pool: Arc<PgPool>,
}

impl PgEventRepository {
    pub fn new(pool: Arc<PgPool>) -> Self {
        Self { pool }
    }

    /// Resolve an existing venue by name or create a new one. Returns the venue ID.
    async fn resolve_or_create_venue(
        tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
        name: &str,
        address: Option<&str>,
    ) -> Result<Uuid, RepoError> {
        // Try to find by name (case-insensitive)
        if let Some(id) = sqlx::query_scalar!(
            r#"SELECT id as "id: Uuid" FROM venues WHERE lower(name) = lower($1)"#,
            name
        )
        .fetch_optional(&mut **tx)
        .await?
        {
            return Ok(id);
        }

        // Create new venue with a slug derived from the name
        let id = Uuid::new_v4();
        let slug = slugify(name);
        sqlx::query!(
            r#"INSERT INTO venues (id, name, slug, address, created_at, updated_at)
               VALUES ($1, $2, $3, $4, now(), now())
               ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name
               RETURNING id as "id: Uuid""#,
            id, name, &slug, address
        )
        .fetch_one(&mut **tx)
        .await?;
        Ok(id)
    }

    /// Resolve an existing artist by name or create a new one. Returns the artist ID.
    async fn resolve_or_create_artist(
        tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
        name: &str,
    ) -> Result<Uuid, RepoError> {
        if let Some(id) = sqlx::query_scalar!(
            r#"SELECT id as "id: Uuid" FROM artists WHERE lower(name) = lower($1)"#,
            name
        )
        .fetch_optional(&mut **tx)
        .await?
        {
            return Ok(id);
        }

        let id = Uuid::new_v4();
        let slug = slugify(name);
        sqlx::query!(
            r#"INSERT INTO artists (id, name, slug, genres, is_local, enrichment_status,
                                    enrichment_attempts, created_at, updated_at)
               VALUES ($1, $2, $3, '{}'::text[], false, 'PENDING', 0, now(), now())
               ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name
               RETURNING id as "id: Uuid""#,
            id, name, &slug
        )
        .fetch_one(&mut **tx)
        .await?;
        Ok(id)
    }
}

// Import the canonical slugify from domain::mod (defined in Phase 2).
// Do NOT redefine slugify here — use crate::domain::slugify for all slug generation
// to ensure consistent slug formatting across venue auto-creation, artist auto-creation,
// and event normalization.
use crate::domain::slugify;

#[async_trait]
impl EventRepository for PgEventRepository {
    async fn upsert(&self, cmd: EventUpsertCommand) -> Result<UpsertResult, RepoError> {
        let mut tx = self.pool.begin().await?;

        // Resolve venue
        let venue_id = Self::resolve_or_create_venue(
            &mut tx,
            &cmd.venue_name,
            cmd.venue_address.as_deref(),
        )
        .await?;

        // Resolve artists
        let mut artist_ids = Vec::with_capacity(cmd.artist_names.len());
        for name in &cmd.artist_names {
            let id = Self::resolve_or_create_artist(&mut tx, name).await?;
            artist_ids.push(id);
        }

        // Upsert event — use xmax to detect created vs updated
        let event_id = Uuid::new_v4();
        let row = sqlx::query!(
            r#"INSERT INTO events (
                   id, slug, title, description, start_time, end_time, doors_time,
                   min_price, max_price, price_tier, ticket_url, image_url,
                   age_restriction, status, venue_id, created_at, updated_at
               ) VALUES (
                   $1, $2, $3, $4, $5, $6, $7,
                   $8, $9, $10, $11, $12,
                   $13, 'ACTIVE', $14, now(), now()
               )
               ON CONFLICT (slug) DO UPDATE SET
                   title = EXCLUDED.title,
                   description = COALESCE(EXCLUDED.description, events.description),
                   start_time = EXCLUDED.start_time,
                   end_time = COALESCE(EXCLUDED.end_time, events.end_time),
                   doors_time = COALESCE(EXCLUDED.doors_time, events.doors_time),
                   min_price = COALESCE(EXCLUDED.min_price, events.min_price),
                   max_price = COALESCE(EXCLUDED.max_price, events.max_price),
                   price_tier = COALESCE(EXCLUDED.price_tier, events.price_tier),
                   ticket_url = COALESCE(EXCLUDED.ticket_url, events.ticket_url),
                   image_url = COALESCE(EXCLUDED.image_url, events.image_url),
                   venue_id = EXCLUDED.venue_id,
                   updated_at = now()
               RETURNING id as "id: Uuid", (xmax::text::int8 <> 0) as "was_updated!""#,
            event_id,
            &cmd.slug,
            &cmd.title,
            cmd.description.as_deref(),
            cmd.start_time,
            cmd.end_time,
            cmd.doors_time,
            cmd.min_price as Option<Decimal>,
            cmd.max_price as Option<Decimal>,
            cmd.price_tier.map(|p| p as i32) as Option<i32>,  // store as text via sqlx::Type
            cmd.ticket_url.as_deref(),
            cmd.image_url.as_deref(),
            cmd.age_restriction as AgeRestriction,
            venue_id,
        )
        .fetch_one(&mut *tx)
        .await?;

        let actual_event_id = row.id;
        let was_updated = row.was_updated;

        // Link artists (idempotent)
        for artist_id in &artist_ids {
            sqlx::query!(
                "INSERT INTO event_artists (event_id, artist_id)
                 VALUES ($1, $2)
                 ON CONFLICT DO NOTHING",
                actual_event_id,
                artist_id
            )
            .execute(&mut *tx)
            .await?;
        }

        // Upsert event_sources
        for source in &cmd.source_attributions {
            let source_id = Uuid::new_v4();
            sqlx::query!(
                r#"INSERT INTO event_sources (id, event_id, source_type, source_identifier,
                                               source_url, confidence_score, source_id, created_at)
                   VALUES ($1, $2, $3, $4, $5, $6, $7, now())
                   ON CONFLICT (event_id, source_type) DO UPDATE SET
                       source_identifier = COALESCE(EXCLUDED.source_identifier, event_sources.source_identifier),
                       source_url = COALESCE(EXCLUDED.source_url, event_sources.source_url),
                       last_scraped_at = now(),
                       confidence_score = EXCLUDED.confidence_score"#,
                source_id,
                actual_event_id,
                source.source_type as crate::domain::source::SourceType,
                source.source_identifier.as_deref(),
                source.source_url.as_deref(),
                source.confidence_score,
                source.source_id.map(|id| id.0),
            )
            .execute(&mut *tx)
            .await?;
        }

        tx.commit().await?;

        if was_updated {
            Ok(UpsertResult::Updated)
        } else {
            Ok(UpsertResult::Created)
        }
    }

    async fn find_by_id(&self, id: EventId) -> Result<Event, RepoError> {
        sqlx::query_as!(
            EventRow,
            r#"SELECT id as "id: Uuid", title, slug, description,
                      start_time, end_time, doors_time,
                      min_price as "min_price: Decimal", max_price as "max_price: Decimal",
                      price_tier as "price_tier: PriceTier",
                      ticket_url, on_sale_date, sold_out, ticket_platform, image_url,
                      age_restriction as "age_restriction: AgeRestriction",
                      status as "status: EventStatus",
                      venue_id as "venue_id: Uuid",
                      title_parsed,
                      event_type as "event_type: EventType",
                      created_at, updated_at
               FROM events WHERE id = $1"#,
            id.0
        )
        .fetch_optional(&*self.pool)
        .await?
        .map(Event::from)
        .ok_or(RepoError::NotFound)
    }

    async fn find_by_slug(&self, slug: &str) -> Result<Option<Event>, RepoError> {
        let row = sqlx::query_as!(
            EventRow,
            r#"SELECT id as "id: Uuid", title, slug, description,
                      start_time, end_time, doors_time,
                      min_price as "min_price: Decimal", max_price as "max_price: Decimal",
                      price_tier as "price_tier: PriceTier",
                      ticket_url, on_sale_date, sold_out, ticket_platform, image_url,
                      age_restriction as "age_restriction: AgeRestriction",
                      status as "status: EventStatus",
                      venue_id as "venue_id: Uuid",
                      title_parsed,
                      event_type as "event_type: EventType",
                      created_at, updated_at
               FROM events WHERE slug = $1"#,
            slug
        )
        .fetch_optional(&*self.pool)
        .await?;
        Ok(row.map(Event::from))
    }

    async fn find_all(
        &self,
        filters: EventFilters,
        page: Pagination,
    ) -> Result<Page<Event>, RepoError> {
        // Build dynamic query with optional filters.
        // Base query joins venues for slug/neighborhood filters.
        let mut count_qb = QueryBuilder::new(
            "SELECT COUNT(DISTINCT e.id) FROM events e LEFT JOIN venues v ON v.id = e.venue_id WHERE 1=1"
        );
        let mut qb = QueryBuilder::new(
            r#"SELECT DISTINCT e.id, e.title, e.slug, e.description,
                      e.start_time, e.end_time, e.doors_time,
                      e.min_price, e.max_price, e.price_tier,
                      e.ticket_url, e.on_sale_date, e.sold_out, e.ticket_platform, e.image_url,
                      e.age_restriction, e.status, e.venue_id, e.title_parsed,
                      e.event_type, e.created_at, e.updated_at
               FROM events e
               LEFT JOIN venues v ON v.id = e.venue_id
               WHERE 1=1"#
        );

        // Apply filters to both count and data queries
        let apply_filters = |qb: &mut QueryBuilder<sqlx::Postgres>| {
            if let Some(from) = &filters.date_from {
                qb.push(" AND e.start_time >= ").push_bind(*from);
            }
            if let Some(to) = &filters.date_to {
                qb.push(" AND e.start_time <= ").push_bind(*to);
            }
            if let Some(slug) = &filters.venue_slug {
                qb.push(" AND (v.slug = ").push_bind(slug.clone())
                  .push(" OR v.display_slug = ").push_bind(slug.clone()).push(")");
            }
            if let Some(neighborhood) = &filters.neighborhood {
                qb.push(" AND v.neighborhood = ").push_bind(neighborhood.clone());
            }
            if let Some(price_max) = &filters.price_max {
                qb.push(" AND e.min_price <= ").push_bind(*price_max);
            }
            if let Some(status) = &filters.status {
                qb.push(" AND e.status = ").push_bind(format!("{status:?}").to_uppercase());
            }
            if let Some(genre) = &filters.genre {
                // Genre filter requires a subquery through event_artists
                qb.push(
                    " AND EXISTS (SELECT 1 FROM event_artists ea JOIN artists a ON a.id = ea.artist_id WHERE ea.event_id = e.id AND "
                ).push_bind(genre.clone()).push(" = ANY(a.genres))");
            }
        };

        apply_filters(&mut count_qb);
        apply_filters(&mut qb);

        let total: i64 = count_qb
            .build_query_scalar()
            .fetch_one(&*self.pool)
            .await?;

        qb.push(" ORDER BY e.start_time ASC LIMIT ")
            .push_bind(page.per_page)
            .push(" OFFSET ")
            .push_bind(page.offset());

        let rows = qb.build_query_as::<EventRow>()
            .fetch_all(&*self.pool)
            .await?;

        Ok(Page {
            items: rows.into_iter().map(Event::from).collect(),
            total,
            page: page.page,
            per_page: page.per_page,
        })
    }

    async fn find_by_venue_id(&self, venue_id: VenueId) -> Result<Vec<Event>, RepoError> {
        let rows = sqlx::query_as!(
            EventRow,
            r#"SELECT id as "id: Uuid", title, slug, description,
                      start_time, end_time, doors_time,
                      min_price as "min_price: Decimal", max_price as "max_price: Decimal",
                      price_tier as "price_tier: PriceTier",
                      ticket_url, on_sale_date, sold_out, ticket_platform, image_url,
                      age_restriction as "age_restriction: AgeRestriction",
                      status as "status: EventStatus",
                      venue_id as "venue_id: Uuid",
                      title_parsed, event_type as "event_type: EventType",
                      created_at, updated_at
               FROM events WHERE venue_id = $1 ORDER BY start_time"#,
            venue_id.0
        )
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(Event::from).collect())
    }

    async fn find_related_events(
        &self,
        event_id: EventId,
        window_days: i64,
    ) -> Result<Vec<Event>, RepoError> {
        let rows = sqlx::query_as!(
            EventRow,
            r#"SELECT e2.id as "id: Uuid", e2.title, e2.slug, e2.description,
                      e2.start_time, e2.end_time, e2.doors_time,
                      e2.min_price as "min_price: Decimal", e2.max_price as "max_price: Decimal",
                      e2.price_tier as "price_tier: PriceTier",
                      e2.ticket_url, e2.on_sale_date, e2.sold_out, e2.ticket_platform, e2.image_url,
                      e2.age_restriction as "age_restriction: AgeRestriction",
                      e2.status as "status: EventStatus",
                      e2.venue_id as "venue_id: Uuid",
                      e2.title_parsed, e2.event_type as "event_type: EventType",
                      e2.created_at, e2.updated_at
               FROM events e1
               JOIN events e2 ON e2.venue_id = e1.venue_id
               WHERE e1.id = $1
                 AND e2.id != $1
                 AND e2.status = 'ACTIVE'
                 AND e2.start_time BETWEEN e1.start_time - ($2 || ' days')::interval
                                       AND e1.start_time + ($2 || ' days')::interval
               ORDER BY e2.start_time"#,
            event_id.0,
            window_days.to_string()
        )
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(Event::from).collect())
    }

    async fn find_upcoming(&self) -> Result<Vec<Event>, RepoError> {
        let rows = sqlx::query_as!(
            EventRow,
            r#"SELECT id as "id: Uuid", title, slug, description,
                      start_time, end_time, doors_time,
                      min_price as "min_price: Decimal", max_price as "max_price: Decimal",
                      price_tier as "price_tier: PriceTier",
                      ticket_url, on_sale_date, sold_out, ticket_platform, image_url,
                      age_restriction as "age_restriction: AgeRestriction",
                      status as "status: EventStatus",
                      venue_id as "venue_id: Uuid",
                      title_parsed, event_type as "event_type: EventType",
                      created_at, updated_at
               FROM events
               WHERE start_time > now() AND status = 'ACTIVE'
               ORDER BY start_time"#
        )
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(Event::from).collect())
    }

    async fn count_upcoming_by_venue(
        &self,
    ) -> Result<Vec<(VenueId, i64)>, RepoError> {
        let rows = sqlx::query!(
            r#"SELECT venue_id as "venue_id: Uuid", COUNT(*) as "count!"
               FROM events
               WHERE start_time > now()
                 AND venue_id IS NOT NULL
                 AND status = 'ACTIVE'
               GROUP BY venue_id"#
        )
        .fetch_all(&*self.pool)
        .await?;

        Ok(rows.into_iter().map(|r| (VenueId(r.venue_id), r.count)).collect())
    }
}

// ---- Row type ----

#[derive(sqlx::FromRow)]
struct EventRow {
    id: Uuid,
    title: String,
    slug: String,
    description: Option<String>,
    start_time: OffsetDateTime,
    end_time: Option<OffsetDateTime>,
    doors_time: Option<OffsetDateTime>,
    min_price: Option<Decimal>,
    max_price: Option<Decimal>,
    price_tier: Option<PriceTier>,
    ticket_url: Option<String>,
    on_sale_date: Option<OffsetDateTime>,
    sold_out: bool,
    ticket_platform: Option<String>,
    image_url: Option<String>,
    age_restriction: AgeRestriction,
    status: EventStatus,
    venue_id: Option<Uuid>,
    title_parsed: bool,
    event_type: Option<EventType>,
    created_at: OffsetDateTime,
    updated_at: OffsetDateTime,
}

impl From<EventRow> for Event {
    fn from(r: EventRow) -> Self {
        Event {
            id: EventId(r.id),
            title: r.title,
            slug: r.slug,
            description: r.description,
            start_time: r.start_time,
            end_time: r.end_time,
            doors_time: r.doors_time,
            min_price: r.min_price,
            max_price: r.max_price,
            price_tier: r.price_tier,
            ticket_url: r.ticket_url,
            on_sale_date: r.on_sale_date,
            sold_out: r.sold_out,
            ticket_platform: r.ticket_platform,
            image_url: r.image_url,
            age_restriction: r.age_restriction,
            status: r.status,
            venue_id: r.venue_id.map(VenueId),
            title_parsed: r.title_parsed,
            event_type: r.event_type,
            created_at: r.created_at,
            updated_at: r.updated_at,
        }
    }
}
```

Note on `event_sources` ON CONFLICT: the current schema (after V21) has no unique constraint on `(event_id, source_type)`. Add a `DO NOTHING` fallback if the constraint doesn't exist:

```sql
INSERT INTO event_sources (...) VALUES (...)
ON CONFLICT DO NOTHING
```

Check the actual V5 migration SQL to confirm whether this constraint exists. If not, upsert with a new `id` each time (INSERT only, no ON CONFLICT).

**Commit:** `feat: pg_events adapter with upsert (xmax), dynamic filters, QueryBuilder`
<!-- END_TASK_4 -->

<!-- START_TASK_5 -->
### Task 5: Verify compilation and AppState wiring

**Step 1: Verify full compilation**

```bash
cargo check 2>&1 | grep "error\[" | head -20
```

Expected: Clean (zero `error[E...]` lines). Fix any import or type mismatch errors.

Common issues:
- `AgeRestriction` vs `age_restriction` field naming — ensure the `From<EventRow>` impl uses the correct field order
- `price_tier` stored as text — verify `PriceTier` has `#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]`
- The `status` filter in `find_all` — `format!("{status:?}").to_uppercase()` is an approximation; use proper enum string conversion

**Step 2: Update BUILD.bazel for :app deps**

Per CLAUDE.md: if a crate is used by `:app` binary, add it to `BUILD.bazel`'s explicit `deps` list. The `main.rs` now imports `sqlx` indirectly (via adapters in lib), and `uuid` is needed. Check if any direct imports in `main.rs` need new Bazel deps:

```python
# In BUILD.bazel, find the :app target and add if needed:
deps = [
    ":lib",
    "@crates//:anyhow",
    "@crates//:axum",
    "@crates//:tokio",
    "@crates//:tracing",
    "@crates//:tracing-subscriber",
    # New if directly imported in main.rs:
    "@crates//:sqlx",  # if used in main.rs directly
],
```

Read `src/main.rs` and check what crates are directly imported with `use`. Only add to `:app` deps what's directly imported there.

**Step 3: Verify Bazel build**

```bash
bazel build //... 2>&1 | tail -20
```

Expected: Builds successfully.

**Commit:** `feat: phase 3 complete — all 6 adapters wired to AppState`
<!-- END_TASK_5 -->

<!-- END_SUBCOMPONENT_B -->

<!-- START_SUBCOMPONENT_C (tasks 6-7) -->

<!-- START_TASK_6 -->
### Task 6: Integration tests

**Verifies:** rust-port.AC1.1, rust-port.AC1.2, rust-port.AC1.3, rust-port.AC1.4

**Files:**
- Create (replace): `tests/integration_db.rs`
- Modify: `tests/BUILD.bazel` — recreate `:integration_db` target
- Modify: `src/adapters/db.rs` — add `reset_for_tests` helper (gated on `test-helpers` feature)

**Prerequisite:** `just dev` must be running on the host machine to provide PostgreSQL access.

**Step 1: Add TestHelper to src/adapters/db.rs**

Append to `src/adapters/db.rs` a `TestHelper` struct behind `cfg(feature = "test-helpers")`:

```rust
#[cfg(feature = "test-helpers")]
pub struct TestHelper {
    pool: Arc<sqlx::PgPool>,
}

#[cfg(feature = "test-helpers")]
impl TestHelper {
    pub fn new(pool: Arc<sqlx::PgPool>) -> Self {
        Self { pool }
    }

    /// Truncate all domain tables in FK-safe order. Call before each integration test.
    ///
    /// IMPORTANT: `venues` and `sources` are intentionally excluded from truncation.
    /// These tables contain seed data inserted by migrations (V8, V9, V11, V14-V20).
    /// Truncating them would destroy seed data that tests like `ac1_3_seed_data_present`
    /// depend on. Integration tests that need a clean venue/source slate should explicitly
    /// truncate those tables in their own setup, not via this helper.
    pub async fn reset(&self) {
        sqlx::query!(
            "TRUNCATE featured_events, event_sources, event_artists, events, ingestion_runs, artists CASCADE"
        )
        .execute(&*self.pool)
        .await
        .expect("Failed to reset test database");
    }
}
```

**Step 2: Create tests/integration_db.rs**

```rust
//! Integration tests against a real PostgreSQL database.
//!
//! Requires `just dev` running on the host to provide PostgreSQL.
//! Run with: `just test-integration`
//!
//! Each test uses `helper.reset()` to start with a clean database.

#![cfg(feature = "test-helpers")]

use std::sync::Arc;

use districtlive_server::adapters::{
    connect, TestHelper, PgArtistRepository, PgEventRepository,
    PgVenueRepository, PgSourceRepository,
};
use districtlive_server::domain::{
    artist::{ArtistId, EnrichmentStatus},
    event::{EventFilters, EventId, EventUpsertCommand, AgeRestriction},
    event_source::SourceAttribution,
    source::SourceType,
    Pagination,
};
use districtlive_server::ports::{ArtistRepository, EventRepository, VenueRepository};
use rust_decimal::Decimal;
use uuid::Uuid;

async fn setup() -> (Arc<sqlx::PgPool>, TestHelper) {
    let url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://app:app@localhost:5432/app".to_owned());
    let pool = Arc::new(connect(&url).await.expect("Failed to connect to test DB"));
    let helper = TestHelper::new(pool.clone());
    helper.reset().await;
    (pool, helper)
}

// ---- Migration tests ----

#[tokio::test]
#[ignore]
async fn ac1_1_migrations_apply_cleanly() {
    // If setup() succeeds, migrations ran without error.
    let (_pool, _helper) = setup().await;
    // Nothing else to assert — connect() already ran migrations
}

#[tokio::test]
#[ignore]
async fn ac1_2_expected_tables_exist() {
    let (pool, _helper) = setup().await;
    for table in &["venues", "artists", "events", "event_artists", "event_sources",
                   "sources", "ingestion_runs", "featured_events"] {
        let count: i64 = sqlx::query_scalar(&format!(
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = '{table}'"
        ))
        .fetch_one(&*pool)
        .await
        .expect("Table check failed");
        assert!(count > 0, "Table {table} should exist");
    }
}

#[tokio::test]
#[ignore]
async fn ac1_3_seed_data_present() {
    let (pool, _helper) = setup().await;
    // Seeds should be present — reset() only truncates non-seed tables
    // Note: if seed data is NOT idempotent across truncate, adjust this test
    let venue_count: i64 = sqlx::query_scalar!("SELECT COUNT(*) FROM venues")
        .fetch_one(&*pool)
        .await
        .expect("Count failed")
        .unwrap_or(0);
    // The seed data from V8 populates DC venues — expect at least 5
    // (exact count depends on all seed migrations V8-V20)
    assert!(venue_count >= 5, "Expected seed venues, got {venue_count}");
}

// ---- Event upsert tests ----

#[tokio::test]
#[ignore]
async fn event_upsert_creates_new_event() {
    let (pool, helper) = setup().await;
    let events = PgEventRepository::new(pool.clone());

    let cmd = test_event_cmd("test-event-create-001");
    let result = events.upsert(cmd).await.expect("Upsert failed");

    use districtlive_server::ports::event_repository::UpsertResult;
    assert_eq!(result, UpsertResult::Created);
}

#[tokio::test]
#[ignore]
async fn ac1_4_event_upsert_updates_on_slug_conflict() {
    let (pool, helper) = setup().await;
    let events = PgEventRepository::new(pool.clone());

    let cmd = test_event_cmd("test-event-dedup-001");
    let first = events.upsert(cmd.clone()).await.expect("First upsert failed");
    let second = events.upsert(cmd).await.expect("Second upsert failed");

    use districtlive_server::ports::event_repository::UpsertResult;
    assert_eq!(first, UpsertResult::Created);
    assert_eq!(second, UpsertResult::Updated);
}

// ---- Artist claim_pending_batch tests ----

#[tokio::test]
#[ignore]
async fn artist_claim_pending_batch_marks_in_progress() {
    let (pool, helper) = setup().await;
    let events = PgEventRepository::new(pool.clone());
    let artists = PgArtistRepository::new(pool.clone());

    // Create an artist by upserting an event with that artist name
    let cmd = test_event_cmd("test-event-for-artist");
    events.upsert(cmd).await.expect("Setup upsert failed");

    // Claim it
    let claimed = artists.claim_pending_batch(10).await.expect("Claim failed");
    assert!(!claimed.is_empty(), "Expected at least one artist to claim");
    assert!(
        claimed.iter().all(|a| a.enrichment_status == EnrichmentStatus::InProgress),
        "All claimed artists should be IN_PROGRESS"
    );
}

#[tokio::test]
#[ignore]
async fn artist_reset_in_progress_to_pending() {
    let (pool, helper) = setup().await;
    let events = PgEventRepository::new(pool.clone());
    let artists = PgArtistRepository::new(pool.clone());

    let cmd = test_event_cmd("test-event-reset");
    events.upsert(cmd).await.expect("Setup failed");
    artists.claim_pending_batch(10).await.expect("Claim failed");

    let reset_count = artists.reset_in_progress_to_pending().await.expect("Reset failed");
    assert!(reset_count > 0, "Expected at least one artist to be reset");

    // Verify they are PENDING again
    let all = artists.find_all(Pagination::default()).await.expect("Find failed");
    let in_progress = all.items.iter().filter(|a| a.enrichment_status == EnrichmentStatus::InProgress).count();
    assert_eq!(in_progress, 0, "No artists should be IN_PROGRESS after reset");
}

// ---- Helpers ----

fn test_event_cmd(slug: &str) -> EventUpsertCommand {
    use time::OffsetDateTime;
    EventUpsertCommand {
        slug: slug.to_owned(),
        title: format!("Test Event {slug}"),
        description: None,
        start_time: OffsetDateTime::now_utc() + time::Duration::days(7),
        end_time: None,
        doors_time: None,
        venue_name: "Black Cat".to_owned(),
        venue_address: Some("1811 14th St NW, Washington, DC 20009".to_owned()),
        artist_names: vec!["Test Artist".to_owned()],
        min_price: Some(Decimal::new(1500, 2)), // $15.00
        max_price: None,
        price_tier: None,
        ticket_url: None,
        image_url: None,
        age_restriction: AgeRestriction::AllAges,
        source_attributions: vec![SourceAttribution {
            source_type: SourceType::Manual,
            source_identifier: None,
            source_url: None,
            confidence_score: Decimal::new(100, 2),
            source_id: None,
        }],
    }
}
```

**Step 3: Recreate :integration_db target in tests/BUILD.bazel**

Read `/workspaces/districtlive-server/tests/BUILD.bazel`. After `just clean-examples` removes the old target, add:

```python
rust_test(
    name = "integration_db",
    srcs = ["integration_db.rs", "support/mod.rs"],
    crate_root = "integration_db.rs",
    edition = "2021",
    tags = ["manual", "external"],
    rustc_env = {"SQLX_OFFLINE": "true"},
    deps = [
        "//:lib_with_test_helpers",
        "@crates//:sqlx",
        "@crates//:tokio",
        "@crates//:time",
        "@crates//:uuid",
        "@crates//:rust_decimal",
    ],
    proc_macro_deps = ["@crates//:async-trait"],
)
```

Note: `@crates//:rust_decimal` uses underscore (not hyphen) in the Bazel label.

**Step 4: Run integration tests**

```bash
just test-integration
```

Expected: All non-`#[ignore]` tests pass. For `#[ignore]` tests, run individually:
```bash
DATABASE_URL=postgres://app:app@localhost:5432/app cargo test --test integration_db -- --ignored --nocapture
```

**Commit:** `test: integration tests for migrations and event/artist adapters`
<!-- END_TASK_6 -->

<!-- START_TASK_7 -->
### Task 7: Regenerate sqlx offline query cache + final verification

**Verifies:** Compilation with `SQLX_OFFLINE=true` (required by Bazel build)

**Prerequisite:** PostgreSQL must be accessible (via `just dev` on host).

**Step 1: Apply migrations to development database**

```bash
DATABASE_URL=postgres://app:app@localhost:5432/app sqlx migrate run
```

Expected: Reports migrations applied (or "no new migrations" if already applied).

**Step 2: Regenerate .sqlx offline data**

```bash
DATABASE_URL=postgres://app:app@localhost:5432/app cargo sqlx prepare
```

Expected: New JSON files created in `.sqlx/` for all `sqlx::query!` and `sqlx::query_as!` calls across the adapters.

**Step 3: Commit .sqlx data**

```bash
git add .sqlx/
git commit -m "chore: regenerate sqlx offline query cache for Phase 3 adapters"
```

**Step 4: Final check**

```bash
just check
```

Expected: `cargo fmt --check` passes, `cargo clippy -- -D warnings` passes with `SQLX_OFFLINE=true`.

**Commit:** `chore: phase 3 verification — just check passing`
<!-- END_TASK_7 -->

<!-- END_SUBCOMPONENT_C -->
