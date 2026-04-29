# DistrictLive Rust Port — Phase 1: Bootstrap

**Goal:** Strip the example domain, port all 21 DB migrations, add required crates, create `Config::from_env()`, and wire a compilable `AppState` skeleton with just config — so every subsequent phase has a solid foundation.

**Architecture:** Infrastructure phase — no domain logic. The example scaffold (Notes + Greeter) is fully removed and replaced with DistrictLive's migrations and a clean `AppState { config: Arc<Config> }`. Later phases add domain types, adapters, and HTTP handlers on top.

**Tech Stack:** Rust 1.85, sqlx 0.8, Cargo + Bazel (`crate_universe`), axum 0.8

**Scope:** Phase 1 of 7 from original design

**Codebase verified:** 2026-04-29

---

## Acceptance Criteria Coverage

This phase implements and tests:

### rust-port.AC1: DB schema and migrations
- **rust-port.AC1.1 Success:** All 21 migrations apply cleanly against a fresh PostgreSQL database via `just test-integration`
- **rust-port.AC1.2 Success:** All expected tables exist after migration: `users`, `venues`, `artists`, `events`, `event_artists`, `event_sources`, `sources`, `ingestion_runs`, `featured_events`
- **rust-port.AC1.3 Success:** Seed data migrations populate `venues` and `sources` tables with the expected DC venue and source records
- **rust-port.AC1.4 Edge:** Running migrations twice does not error — sqlx migration tracking prevents re-application

---

<!-- START_SUBCOMPONENT_A (tasks 1-2) -->

<!-- START_TASK_1 -->
### Task 1: Run just clean-examples

**Verifies:** None (infrastructure)

**Files:**
- Deleted by script: `src/adapters/pg_notes.rs`, `src/ports/notes.rs`, `tests/integration_db.rs`, `migrations/0001_notes.sql`
- Stripped by script: `@EXAMPLE-BLOCK` regions in `src/adapters/mod.rs`, `src/ports/mod.rs`, `src/http/mod.rs`, `src/main.rs`, `tests/api.rs`, `tests/support/mod.rs`, `tests/BUILD.bazel`

**Step 1: Run the cleanup script**

```bash
just clean-examples
```

Expected: Script runs, `cargo fmt` normalizes whitespace, exits cleanly.

**Step 2: Verify Notes example is gone**

```bash
ls src/adapters/ src/ports/ migrations/
```

Expected:
- `src/adapters/`: `mod.rs`, `static_greeter.rs` (no `pg_notes.rs`)
- `src/ports/`: `mod.rs`, `greeting.rs` (no `notes.rs`)
- `migrations/`: empty directory

**Step 3: Confirm it still compiles**

```bash
cargo check 2>&1 | grep -c error || echo "Clean"
```

Expected: Outputs `Clean` (zero errors). Greeter still in place; app compiles.

**Commit:** `chore: remove notes/greeter example via just clean-examples`
<!-- END_TASK_1 -->

<!-- START_TASK_2 -->
### Task 2: Remove Greeter example

The design replaces `AppState` with a clean Config-only skeleton. The Greeter example (`GreetingPort`, `StaticGreeter`, `/api/greet` handler, property tests) is not part of the DistrictLive domain and must be removed manually — `just clean-examples` intentionally preserves it as a reference.

**Files:**
- Delete: `src/ports/greeting.rs`
- Delete: `src/adapters/static_greeter.rs`
- Modify: `src/ports/mod.rs` — remove greeter exports
- Modify: `src/adapters/mod.rs` — remove `static_greeter` module
- Modify: `src/http/mod.rs` — remove greet handler, `greeter` field from AppState
- Modify: `src/main.rs` — remove `StaticGreeter` construction
- Modify: `tests/api.rs` — remove greet endpoint tests
- Modify: `tests/support/mod.rs` — remove `FakeGreeter`
- Modify: `tests/properties.rs` — remove `StaticGreeter` property tests

**Step 1: Delete the greeter source files**

```bash
rm src/ports/greeting.rs src/adapters/static_greeter.rs
```

**Step 2: Update src/ports/mod.rs**

Read the file. Remove:
- `pub mod greeting;`
- Any `pub use greeting::{...}` re-exports

Leave the file with only what remains after clean-examples (likely empty or just an outer comment).

**Step 3: Update src/adapters/mod.rs**

Read the file. Remove:
- `pub mod static_greeter;`
- Any `pub use static_greeter::StaticGreeter;`

**Step 4: Update src/http/mod.rs**

Read the file. Remove:
- The `greeter: Arc<dyn GreetingPort>` field from `AppState`
- Any `use` imports of `GreetingPort` or `GreetError`
- The greet route (e.g., `.route("/api/greet", get(greet_handler))`)
- Any `mod greet;` or `pub mod greeting;` sub-module declarations
- Any greet handler function defined in this file

Leave `AppState` as an empty struct for now (Task 3 adds the config field):

```rust
#[derive(Clone)]
pub struct AppState {}
```

**Step 5: Update src/main.rs**

Read the file. Remove:
- `use districtlive_server::adapters::StaticGreeter;`
- The `StaticGreeter::new()` or `StaticGreeter` construction call
- The `greeter` field in the `AppState { ... }` constructor

**Step 6: Update tests/api.rs and tests/support/mod.rs**

Read `tests/api.rs`. Remove:
- Any test functions that call `/api/greet`
- Any `FakeGreeter` usage

Read `tests/support/mod.rs`. Remove:
- The `FakeGreeter` struct and its `GreetingPort` impl

**Step 7: Update tests/properties.rs**

Read the file. Remove all `StaticGreeter` tests. After removal, the file should still be valid Rust (keep `proptest` imports and any boilerplate needed for an empty test module, or remove entirely if nothing remains).

**Step 8: Verify compilation**

```bash
cargo check 2>&1 | grep error || echo "Clean"
```

Expected: `Clean`. If errors remain, they are likely dangling `use` imports — remove them.

**Commit:** `chore: remove greeter example, stub AppState for DistrictLive`
<!-- END_TASK_2 -->

<!-- END_SUBCOMPONENT_A -->

<!-- START_SUBCOMPONENT_B (tasks 3-5) -->

<!-- START_TASK_3 -->
### Task 3: Create src/config.rs and wire AppState skeleton

**Verifies:** None (infrastructure — Config values are used in Phase 4+)

**Files:**
- Create: `src/config.rs`
- Create: `src/ingestion/mod.rs` (empty stub)
- Create: `src/enrichment/mod.rs` (empty stub)
- Modify: `src/lib.rs` — add `pub mod config`, `pub mod ingestion`, `pub mod enrichment`
- Modify: `src/http/mod.rs` — populate AppState with `config: Arc<Config>`
- Modify: `src/main.rs` — initialize Config, wire into AppState

**Step 1: Create src/config.rs**

```rust
//! Application configuration loaded from environment variables.
//!
//! All field names map to their uppercase `SCREAMING_SNAKE_CASE` env var equivalent
//! (e.g., `database_url` ← `DATABASE_URL`). Optional fields use `Option<T>` or
//! have sensible defaults for local development.

use anyhow::Context as _;
use std::{env, net::SocketAddr};

#[derive(Clone, Debug)]
pub struct Config {
    // --- Core ---
    pub database_url: String,
    pub bind_addr: SocketAddr,

    // --- Admin ---
    /// HTTP Basic auth username for /api/admin/* routes.
    pub admin_username: String,
    /// HTTP Basic auth password for /api/admin/* routes.
    pub admin_password: String,

    // --- Ingestion ---
    pub ingestion_enabled: bool,
    /// Cron expression for API-based connectors (Ticketmaster, Bandsintown, Dice.fm).
    /// Default: every 6 hours.
    pub ingestion_api_cron: String,
    /// Cron expression for scraper-based connectors (venue websites).
    /// Default: every 6 hours.
    pub ingestion_scraper_cron: String,

    // --- Connectors ---
    pub ticketmaster_api_key: Option<String>,
    pub bandsintown_app_id: Option<String>,
    /// Comma-separated Dice.fm venue slugs to ingest (e.g. "black-cat,dc9").
    pub dicefm_venue_slugs: Vec<String>,

    // --- Enrichment ---
    pub enrichment_enabled: bool,
    /// Cron expression for artist enrichment batches. Default: every 2 hours.
    pub enrichment_cron: String,
    /// MusicBrainz name-match score threshold (0.0–1.0). Default: 0.7.
    pub musicbrainz_confidence_threshold: f64,
    pub spotify_enabled: bool,
    pub spotify_client_id: Option<String>,
    pub spotify_client_secret: Option<String>,

    // --- Notifications ---
    pub discord_webhook_url: Option<String>,
}

impl Config {
    /// Load configuration from environment variables.
    ///
    /// Required variables: `DATABASE_URL`.
    /// All others have defaults suitable for local development.
    pub fn from_env() -> anyhow::Result<Self> {
        Ok(Self {
            database_url: required("DATABASE_URL")?,
            bind_addr: env::var("BIND_ADDR")
                .unwrap_or_else(|_| "0.0.0.0:8080".to_owned())
                .parse::<SocketAddr>()
                .context("Invalid BIND_ADDR — expected format: host:port")?,
            admin_username: env::var("ADMIN_USERNAME")
                .unwrap_or_else(|_| "admin".to_owned()),
            admin_password: env::var("ADMIN_PASSWORD")
                .unwrap_or_else(|_| "changeme".to_owned()),
            ingestion_enabled: bool_flag("INGESTION_ENABLED"),
            ingestion_api_cron: env::var("INGESTION_API_CRON")
                .unwrap_or_else(|_| "0 0 */6 * * *".to_owned()),
            ingestion_scraper_cron: env::var("INGESTION_SCRAPER_CRON")
                .unwrap_or_else(|_| "0 30 */6 * * *".to_owned()),
            ticketmaster_api_key: env::var("TICKETMASTER_API_KEY").ok(),
            bandsintown_app_id: env::var("BANDSINTOWN_APP_ID").ok(),
            dicefm_venue_slugs: env::var("DICEFM_VENUE_SLUGS")
                .map(|s| {
                    s.split(',')
                        .map(str::trim)
                        .filter(|s| !s.is_empty())
                        .map(str::to_owned)
                        .collect()
                })
                .unwrap_or_default(),
            enrichment_enabled: bool_flag("ENRICHMENT_ENABLED"),
            enrichment_cron: env::var("ENRICHMENT_CRON")
                .unwrap_or_else(|_| "0 0 */2 * * *".to_owned()),
            musicbrainz_confidence_threshold: env::var("MUSICBRAINZ_CONFIDENCE_THRESHOLD")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(0.7),
            spotify_enabled: bool_flag("SPOTIFY_ENABLED"),
            spotify_client_id: env::var("SPOTIFY_CLIENT_ID").ok(),
            spotify_client_secret: env::var("SPOTIFY_CLIENT_SECRET").ok(),
            discord_webhook_url: env::var("DISCORD_WEBHOOK_URL").ok(),
        })
    }
}

fn required(name: &str) -> anyhow::Result<String> {
    env::var(name)
        .map_err(|_| anyhow::anyhow!("Required environment variable `{}` is not set", name))
}

/// Returns `true` if the env var is set to `"true"`, `"1"`, or `"yes"` (case-insensitive).
fn bool_flag(name: &str) -> bool {
    matches!(
        env::var(name).as_deref().map(str::to_ascii_lowercase).as_deref(),
        Ok("true") | Ok("1") | Ok("yes")
    )
}

/// Test-only constructor with sensible defaults. Avoids reading environment variables.
///
/// Used by `tests/support/mod.rs` to build a test AppState without live config.
/// `SocketAddr` does not implement `Default`, so a blanket `#[derive(Default)]` will not
/// compile — this method is the intended substitute.
#[cfg(any(test, feature = "test-helpers"))]
pub fn test_default() -> Self {
    Self {
        database_url: "postgres://test:test@localhost/test".to_owned(),
        bind_addr: "127.0.0.1:0".parse().expect("valid addr"),
        admin_username: "testuser".to_owned(),
        admin_password: "testpass".to_owned(),
        ingestion_enabled: false,
        ingestion_api_cron: "0 0 * * * *".to_owned(),
        ingestion_scraper_cron: "0 0 * * * *".to_owned(),
        ticketmaster_api_key: None,
        bandsintown_app_id: None,
        dicefm_venue_slugs: vec![],
        enrichment_enabled: false,
        enrichment_cron: "0 0 * * * *".to_owned(),
        musicbrainz_confidence_threshold: 0.9,
        spotify_enabled: false,
        spotify_client_id: None,
        spotify_client_secret: None,
        discord_webhook_url: None,
    }
}
```

**Step 2: Create stub pipeline modules**

Create `/workspaces/districtlive-server/src/ingestion/mod.rs`:
```rust
// Ingestion pipeline — normalization, deduplication, orchestration, and scheduler.
// Implemented in Phase 5.
```

Create `/workspaces/districtlive-server/src/enrichment/mod.rs`:
```rust
// Enrichment pipeline — MusicBrainz and Spotify enrichers, orchestration, and scheduler.
// Implemented in Phase 6.
```

**Step 3: Update src/lib.rs**

Read `/workspaces/districtlive-server/src/lib.rs`. Add the three new module declarations:

```rust
pub mod config;
pub mod enrichment;
pub mod ingestion;
```

The existing `pub mod adapters; pub mod domain; pub mod http; pub mod ports;` declarations remain.

**Step 4: Update AppState in src/http/mod.rs**

Read the file. Replace the stub `AppState {}` (from Task 2) with:

```rust
use crate::config::Config;
use std::sync::Arc;

#[derive(Clone)]
pub struct AppState {
    pub config: Arc<Config>,
}
```

The `create_router` function signature becomes:

```rust
pub fn create_router(state: AppState) -> axum::Router {
    axum::Router::new()
        .route("/healthz", axum::routing::get(healthz))
        .with_state(state)
}
```

The `healthz` handler remains unchanged.

**Step 5: Update src/main.rs**

Read `/workspaces/districtlive-server/src/main.rs`. Replace the current startup with:

```rust
use districtlive_server::{config::Config, http::{create_router, AppState}};
use std::sync::Arc;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into()),
        )
        .init();

    let config = Arc::new(Config::from_env()?);
    let bind_addr = config.bind_addr;
    let state = AppState { config };
    let app = create_router(state);

    let listener = tokio::net::TcpListener::bind(bind_addr).await?;
    tracing::info!("Listening on {bind_addr}");

    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await?;

    Ok(())
}

async fn shutdown_signal() {
    use tokio::signal;
    let ctrl_c = async {
        signal::ctrl_c().await.expect("failed to install Ctrl+C handler");
    };
    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("failed to install SIGTERM handler")
            .recv()
            .await;
    };
    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();
    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }
}
```

Keep the existing pattern for graceful shutdown if the scaffold already has it.

**Step 6: Verify compilation**

```bash
cargo check 2>&1
```

Expected: Compiles cleanly. Fix any "unused import" or "dead code" warnings.

**Commit:** `feat: add Config::from_env(), module stubs, wire AppState with config`
<!-- END_TASK_3 -->

<!-- START_TASK_4 -->
### Task 4: Add crates to Cargo.toml and repin

**Verifies:** None (infrastructure)

**Files:**
- Modify: `Cargo.toml`

**Step 1: Add crates to Cargo.toml**

Read `/workspaces/districtlive-server/Cargo.toml`. In the `[dependencies]` section, add the following after the existing deps:

```toml
# HTML scraping — venue website connectors (Phase 5)
scraper = "0.26"

# Async HTTP client — all connectors and enrichers (Phase 5+)
reqwest = { version = "0.12", features = ["json", "rustls-tls"], default-features = false }

# Cron-scheduled async tasks — ingestion and enrichment schedulers (Phase 5+)
tokio-cron-scheduler = "0.13"

# Additional Axum utilities — TypedHeader for Basic auth (Phase 4)
axum-extra = { version = "0.10", features = ["typed-header"] }

# Exact decimal arithmetic — price/money fields (Phase 2+)
rust_decimal = { version = "1", features = ["serde"] }

# Base64 encoding — used by Basic auth test helpers (Phase 4 tests)
base64 = "0.22"
```

Note: Version ranges are intentional here. Run `cargo update` below to resolve exact versions into `Cargo.lock`, then the lockfile pins them exactly.

**Step 2: Resolve new dependencies**

```bash
cargo update
```

Expected: New entries added to `Cargo.lock` for the five crates. No errors.

**Step 3: Verify Cargo.lock contains the new crates**

```bash
grep -E "^name = \"(scraper|reqwest|tokio-cron-scheduler|axum-extra|rust_decimal)\"" Cargo.lock
```

Expected: Each of the five crate names appears at least once.

**Step 4: Repin Bazel crate_universe**

```bash
just bazel-repin
```

Expected: `MODULE.bazel.lock` updated. Command takes 1–3 minutes — it fetches crate metadata. No errors.

**Step 5: Verify Bazel still builds**

```bash
cargo check 2>&1 | grep error || echo "Clean"
```

Expected: `Clean`. The new crates are now in the lockfile but not yet imported by any source file.

**Commit:** `chore: add scraper, reqwest, tokio-cron-scheduler, axum-extra, rust_decimal`
<!-- END_TASK_4 -->

<!-- START_TASK_5 -->
### Task 5: Port 21 Flyway migrations to sqlx format

**Verifies:** rust-port.AC1.1, rust-port.AC1.2, rust-port.AC1.3, rust-port.AC1.4

**Files:**
- Create: `migrations/0001_init.sql` through `migrations/0021_add_source_id_to_event_sources.sql`

The Flyway migrations live at:
`/workspaces/districtlive-server/kotlin-src/src/main/resources/db/migration/`

The full mapping of Flyway filename → sqlx filename:

| Flyway (source) | sqlx (destination) |
|-----------------|-------------------|
| `V1__init.sql` | `0001_init.sql` |
| `V2__create_venues.sql` | `0002_create_venues.sql` |
| `V3__create_artists.sql` | `0003_create_artists.sql` |
| `V4__create_events.sql` | `0004_create_events.sql` |
| `V5__create_event_sources.sql` | `0005_create_event_sources.sql` |
| `V6__create_sources.sql` | `0006_create_sources.sql` |
| `V7__create_ingestion_runs.sql` | `0007_create_ingestion_runs.sql` |
| `V8__seed_venues.sql` | `0008_seed_venues.sql` |
| `V9__seed_sources.sql` | `0009_seed_sources.sql` |
| `V10__rename_atlantis_venue.sql` | `0010_rename_atlantis_venue.sql` |
| `V11__seed_ticketmaster_dc_venues.sql` | `0011_seed_ticketmaster_dc_venues.sql` |
| `V12__add_featured_events.sql` | `0012_add_featured_events.sql` |
| `V13__artist_enrichment.sql` | `0013_artist_enrichment.sql` |
| `V14__deterministic_venue_uuids.sql` | `0014_deterministic_venue_uuids.sql` |
| `V15__venue_display_overrides.sql` | `0015_venue_display_overrides.sql` |
| `V16__seed_dc9_source.sql` | `0016_seed_dc9_source.sql` |
| `V17__event_slug_unique.sql` | `0017_event_slug_unique.sql` |
| `V18__seed_dicefm_source_and_venues.sql` | `0018_seed_dicefm_source_and_venues.sql` |
| `V19__seed_pieshop_cpp_sources.sql` | `0019_seed_pieshop_cpp_sources.sql` |
| `V20__seed_union_stage_presents.sql` | `0020_seed_union_stage_presents.sql` |
| `V21__add_source_id_to_event_sources.sql` | `0021_add_source_id_to_event_sources.sql` |

**Step 1: Read each Flyway migration and create the sqlx equivalent**

For each of the 21 files: read the Kotlin source file and create the corresponding file in `migrations/` with identical SQL content. The SQL is standard PostgreSQL DDL/DML — it is directly compatible with sqlx migrations without modification.

Use this shell loop to copy all 21 files at once:

```bash
KOTLIN_MIGRATIONS="kotlin-src/src/main/resources/db/migration"
for n in $(seq 1 21); do
    src=$(ls "${KOTLIN_MIGRATIONS}/V${n}__"*.sql 2>/dev/null | head -1)
    if [ -z "$src" ]; then echo "Missing V${n}"; continue; fi
    basename_part=$(basename "$src" | sed "s/V${n}__/$(printf '%04d' $n)_/")
    cp "$src" "migrations/${basename_part}"
    echo "Created migrations/${basename_part}"
done
```

**Step 2: Verify all 21 files were created**

```bash
ls migrations/ | sort
```

Expected: Exactly 21 files, named `0001_init.sql` through `0021_add_source_id_to_event_sources.sql`.

**Step 3: Verify migration content (spot-check)**

Read `migrations/0008_seed_venues.sql` and verify it contains DC venue INSERT statements (this is the venue seed migration, `V8__seed_venues.sql`). Read `migrations/0009_seed_sources.sql` and verify it contains source INSERT statements.

**Step 4: Update sqlx offline query data (requires Postgres)**

sqlx uses a `.sqlx/` directory for compile-time query verification in offline mode (`SQLX_OFFLINE=true`). This step requires the PostgreSQL instance to be running (via `just dev` on the host).

If Postgres is available:
```bash
# Apply migrations
DATABASE_URL=postgres://app:app@localhost:5432/app sqlx migrate run

# Regenerate .sqlx offline data
DATABASE_URL=postgres://app:app@localhost:5432/app cargo sqlx prepare
```

If Postgres is not available right now, skip this step. The `.sqlx/` data will be regenerated in Phase 3 when the full adapter queries are written.

**Step 5: Verify migrations apply cleanly twice (AC1.4)**

If Postgres is available:
```bash
DATABASE_URL=postgres://app:app@localhost:5432/app sqlx migrate run
```

Expected: Second run outputs `Applied 0 migrations` (sqlx tracks applied migrations in `_sqlx_migrations` table — no re-application).

**Step 6: Commit**

```bash
git add migrations/
git commit -m "feat: port 21 Flyway migrations to sqlx format"
```
<!-- END_TASK_5 -->

<!-- END_SUBCOMPONENT_B -->

<!-- START_TASK_6 -->
### Task 6: Final Phase 1 verification

**Verifies:** None (verification)

**Step 1: Run full check (fmt + clippy)**

```bash
just check
```

Expected: Passes without errors. Fix any clippy `-D warnings` issues before proceeding.

Common issues to watch for:
- Unused imports left over from greeter removal
- Dead code warnings on `Config` fields not yet referenced
- Formatting issues in the new files

If clippy warns on Config fields being unused, suppress temporarily with `#[expect(dead_code)]` on the Config struct (not individual fields). Per Rust house style, `#[expect]` is preferred over `#[allow]` because it emits a warning when the suppression is no longer needed:

```rust
#[derive(Clone, Debug)]
#[expect(dead_code, reason = "all fields used by Phase 4+; remove this attribute then")]
pub struct Config { ... }
```

Remove this `#[expect]` attribute in Phase 4 once all Config fields are consumed by HTTP handlers and middleware.

**Step 2: Run unit + property tests**

```bash
just test
```

Expected: All tests pass. After removing greeter tests, `tests/properties.rs` and `tests/api.rs` should still compile and pass (healthz test at minimum).

**Step 3: Verify healthz endpoint (if just dev is running)**

```bash
curl -s http://localhost:8080/healthz
```

Expected: `{"status":"ok"}` or similar JSON response.

**Commit:** `chore: phase 1 verification — just check and just test passing`
<!-- END_TASK_6 -->
