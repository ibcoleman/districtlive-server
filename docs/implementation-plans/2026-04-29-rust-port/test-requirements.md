# Test Requirements: DistrictLive Rust Port

## Summary

This document maps each acceptance criterion from the DistrictLive Rust Port design plan to its verification approach: either an automated test (with target file, test name, type, and what it verifies) or a human verification step (with justification and procedure). The mapping has been rationalized against the implementation decisions captured in `phase_01.md` through `phase_07.md`.

Coverage breakdown:
- **AC1 (Migrations):** 4 criteria, all automated via integration tests in `tests/integration_db.rs`.
- **AC2 (Public API):** 8 criteria, mostly automated via handler tests in `tests/api.rs` plus integration tests for filter behavior; full venue/artist hydration verified by integration test.
- **AC3 (Ingestion):** 8 criteria, mix of unit fixture tests, property tests, integration tests, and one human smoke test for the end-to-end manual trigger when `INGESTION_ENABLED=true`.
- **AC4 (Enrichment):** 5 criteria, integration tests for state machine + a unit test for the Spotify gating; one human verification for AC4.1 happy path against live MusicBrainz.
- **AC5 (Admin Auth):** 7 criteria, fully automated via handler tests with fakes in `tests/api.rs`.
- **AC6 (Frontend):** 4 criteria; AC6.1 automated via `pnpm build` exit status; AC6.2–AC6.4 require human verification because they verify rendering and DOM interaction in a real browser.
- **AC7 (Test Coverage):** 4 criteria, all automated via existing test suites and `just check`.

The general principle: a real PostgreSQL database is exercised via `tests/integration_db.rs` (gated by `#[ignore]` and `manual` Bazel tag, run via `just test-integration`). Pure Rust handler/middleware behavior is verified in `tests/api.rs` against fake adapters from `tests/support/mod.rs`. Property-based tests for pure logic live in `tests/properties.rs`. Connector parsing is verified against saved fixtures in `tests/connector_tests.rs`. Browser rendering and end-to-end UI interaction are verified by humans because the project intentionally has no JS test runner or browser automation in scope.

---

## rust-port.AC1: DB schema and migrations

### rust-port.AC1.1 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac1_1_migrations_apply_cleanly`
- **Verifies:** `connect()` runs all 21 migrations against a fresh PostgreSQL database without error. The test calls `setup()` (which calls `connect()` from `src/adapters/db.rs`) and asserts no panic. Per Phase 1 Task 5 and Phase 3 Task 1, `connect()` runs `sqlx::migrate!("./migrations").run(&pool)` at startup; a failure on any of the 21 migration files causes `setup()` to fail.

### rust-port.AC1.2 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac1_2_expected_tables_exist`
- **Verifies:** After migrations run, every expected table is present. Iterates over `["venues", "artists", "events", "event_artists", "event_sources", "sources", "ingestion_runs", "featured_events"]` and queries `information_schema.tables` for each, asserting count > 0. (The `users` table from V1 is also created but is not referenced in domain code; the test list matches what subsequent phases consume.)

### rust-port.AC1.3 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac1_3_seed_data_present`
- **Verifies:** Seed migrations V8 (venues), V9/V11/V14–V20 (sources) populated their target tables. Asserts `SELECT COUNT(*) FROM venues >= 5`. Phase 3 fix #41 ensured `TestHelper::reset()` does NOT truncate `venues` or `sources`, so seed data survives between tests and this assertion is meaningful.

### rust-port.AC1.4 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac1_4_event_upsert_updates_on_slug_conflict`
- **Verifies:** sqlx's `_sqlx_migrations` tracking + idempotent upsert behavior. Calls `events.upsert(cmd)` twice with the same slug, asserts the first returns `UpsertResult::Created` and the second returns `UpsertResult::Updated`. This indirectly proves migrations are not re-applied on each `connect()` (otherwise the second call would see a fresh table and `Created` again). A more direct test is implicit: `setup()` calls `connect()` for every test, and any re-application attempt would fail with a duplicate object error.

---

## rust-port.AC2: Public read API

### rust-port.AC2.1 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac2_1_list_events_returns_paginated_shape`
- **Verifies:** A real DB-backed call to `GET /api/events` (via `axum_test::TestServer` wired with the `Pg*` adapters from `setup()`) returns JSON whose top level matches `PageDto<EventDto>` and whose first `items[0]` contains the fields `title`, `slug`, `venue`, `artists`, `start_time`, `min_price`, `max_price`, and `status`. Requires upserting at least one event in the test setup. Cannot be reliably done with the empty fakes in `tests/api.rs` because they always return an empty page; the shape contract is best verified end-to-end against real data.

### rust-port.AC2.2 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac2_2_event_filters_narrow_results`
- **Verifies:** Each filter parameter (`date_from`, `date_to`, `venue_slug`, `genre`, `neighborhood`, `price_max`, `status`) independently narrows the result set. Seeds three events at different venues/dates/prices, then issues 7 filtered requests (one per filter dimension) and asserts each returns only the matching subset. Exercises the `QueryBuilder`-driven `find_all` from Phase 3 Task 4.

### rust-port.AC2.3 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac2_3_event_detail_includes_venue_artists_related`
- **Verifies:** `GET /api/events/{id}` returns an `EventDetailDto` with the venue object populated (from `find_by_id` via `state.venues`), the artist list populated (from event_artists join), and `related_events` populated with up to N other events at the same venue within ±7 days. Seeds the target event plus one related event 3 days later and one unrelated event at a different venue, then asserts `related_events` has exactly the one entry.

### rust-port.AC2.4 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac2_4_venues_neighborhood_filter`
- **Verifies:** `GET /api/venues?neighborhood=...` calls `find_by_neighborhood`, returning only venues whose `neighborhood` column matches. Uses seed data (V8) which already includes DC venues with neighborhood values.

### rust-port.AC2.5 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac2_5_artists_local_filter`
- **Verifies:** `GET /api/artists?local=true` calls `find_local`, returning only artists with `is_local = true`. Inserts two artists (one local, one not) and asserts the response contains exactly one item.

### rust-port.AC2.6 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac2_6_featured_returns_most_recent`
- **Verifies:** `GET /api/featured` returns the most recently created featured event with full event detail and blurb. Inserts two featured rows (older + newer), asserts the response's `id` matches the newer one and `event` is hydrated. Exercises `pg_featured`'s `find_current` (`ORDER BY created_at DESC LIMIT 1`) from Phase 3 Task 2.

### rust-port.AC2.7 [automated]
- **Type:** unit (handler with fake)
- **File:** `tests/api.rs`
- **Test name:** `get_event_unknown_id_returns_404`
- **Verifies:** `GET /api/events/{unknown_uuid}` returns HTTP 404. The `EmptyEventRepository` fake returns `RepoError::NotFound`, which `ApiError::Repo(RepoError::NotFound)` maps to `StatusCode::NOT_FOUND` per `src/http/error.rs`. Already specified in Phase 4 Task 6.

### rust-port.AC2.8 [automated]
- **Type:** unit (handler)
- **File:** `tests/api.rs`
- **Test name:** `list_events_bad_date_returns_400`
- **Verifies:** `GET /api/events?date_from=not-a-date` returns HTTP 400. Axum's `Query<EventsQuery>` extractor fails to deserialize the malformed ISO8601 string via `time::serde::iso8601::option`, returning a 400 by default for query rejection. Already specified in Phase 4 Task 6.

---

## rust-port.AC3: Ingestion pipeline

### rust-port.AC3.1 [automated]
- **Type:** unit (fixture)
- **File:** `tests/connector_tests.rs`
- **Test names (one per connector):**
  - `ticketmaster_parses_fixture`
  - `bandsintown_parses_fixture`
  - `dicefm_parses_fixture_with_events`
  - `dicefm_empty_fixture_returns_no_events`
  - `black_cat_parses_fixture`
  - `dc9_parses_fixture`
  - `comet_ping_pong_parses_listing_fixture`
  - `pie_shop_parses_listing_fixture`
  - `rhizome_dc_parses_fixture`
  - `seven_drum_city_parses_fixture`
  - `union_stage_presents_parses_listing_fixture`
- **Verifies:** Each connector's `parse(...)` (or equivalent `parse_listing`/`parse_html`/`parse_json`) entry point loads its corresponding fixture file via `include_str!` and produces `Vec<RawEvent>` with at least one element where `title`, `venue_name`, and `start_time` are non-empty/valid. The shared `assert_valid_raw_event!` macro from Phase 5 Task 9 enforces these invariants. Empty fixtures (e.g., `dicefm-empty-events.html`, `comet-ping-pong-empty.html`) verify the connector returns an empty Vec without erroring.

### rust-port.AC3.2 [automated]
- **Type:** property
- **File:** `tests/properties.rs`
- **Test names:** `slug_is_non_empty_for_valid_input`, `slug_is_url_safe`
- **Verifies:** For arbitrary `(title, venue)` strings drawn from a non-empty alphanumeric/symbolic alphabet, `generate_slug(title, venue, OffsetDateTime::now_utc())` returns a non-empty string composed only of lowercase ASCII alphanumerics and hyphens, with no leading or trailing hyphen. Per Phase 5 Task 9.

### rust-port.AC3.3 [automated]
- **Type:** unit (logic)
- **File:** `tests/properties.rs` (or a new `tests/deduplication_test.rs`)
- **Test name:** `deduplication_merges_matching_slugs`
- **Verifies:** Given two `NormalizedEvent`s sharing the same slug (constructed by hand to share venue + date + similar title), `DeduplicationService::deduplicate` returns one `DeduplicatedEvent` whose `sources` Vec contains both source attributions. Complements the property test below; this is a direct example-based test of the merge behavior.

### rust-port.AC3.4 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac3_4_admin_trigger_returns_stats`
- **Verifies:** When `INGESTION_ENABLED=true` (set via `Config::test_default()` override in this test only), `POST /api/admin/ingest/trigger` (with valid Basic auth) returns HTTP 200 and a JSON body containing the keys `events_fetched`, `events_created`, `events_updated`, `events_deduplicated`. Uses a stub `SourceConnector` that returns a fixed pair of `RawEvent`s so the orchestrator path is fully exercised against the real DB. Per Phase 5 Task 7.

### rust-port.AC3.5 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac3_5_ingestion_run_lifecycle`
- **Verifies:** Calling `IngestionOrchestrator::run_connector` with a stub connector (1) inserts an `ingestion_runs` row with `status = 'RUNNING'` and (2) updates that same row to `status = 'SUCCESS'` plus populated `events_fetched`/`events_created`/`completed_at` after the pipeline completes. Performs a query between the orchestrator step and its completion is impractical inside one test; instead the test asserts the final row state and that exactly one row was created for the source.

### rust-port.AC3.6 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac3_6_repeat_connector_run_updates_existing_event`
- **Verifies:** Running the orchestrator twice with the same stub `SourceConnector` (same `RawEvent`s) produces two `ingestion_runs` rows. The second run's stats show `events_updated >= 1` and `events_created == 0`, proving slug conflict resolved to UPDATE rather than INSERT. Also asserts `SELECT COUNT(*) FROM events WHERE slug = ...` is exactly 1 after both runs.

### rust-port.AC3.7 [automated]
- **Type:** unit
- **File:** `tests/properties.rs` (or inline test in `src/ingestion/normalization.rs`)
- **Test name:** `placeholder_titles_are_filtered`
- **Verifies:** `NormalizationService::is_placeholder` returns `true` for the strings `"private event"`, `"tba"`, `"to be announced"`, `"sold out"`, `"coming soon"`, and case variants thereof. Verifies the orchestrator's filter step in Phase 5 Task 7 will drop these entries before upsert.

### rust-port.AC3.8 [automated]
- **Type:** unit (handler)
- **File:** `tests/api.rs`
- **Test name:** `admin_ingest_trigger_when_disabled_returns_400`
- **Verifies:** With the test `AppState` whose `Config.ingestion_enabled = false` (default in `Config::test_default()`), `POST /api/admin/ingest/trigger` (with valid Basic auth) returns HTTP 400 and a JSON error body containing `"ingestion is disabled"`. Wired via `ApiError::Ingestion(IngestionError::Disabled)` → `StatusCode::BAD_REQUEST` mapping in `src/http/error.rs`.

---

## rust-port.AC4: Artist enrichment pipeline

### rust-port.AC4.1 [partially automated + human]

**Automated portion** [unit]
- **File:** `src/adapters/enrichers/musicbrainz.rs` (inline `#[cfg(test)] mod tests`)
- **Test name:** `musicbrainz_parse_response_extracts_canonical_name_mbid_tags`
- **Verifies:** `MusicBrainzEnricher::parse_response(json, queried_name, threshold)` returns `Some(EnrichmentResult)` with `canonical_name`, `external_id` (the MBID), and non-empty `tags` for a saved fixture of a real MusicBrainz response (e.g., a known artist). This avoids any HTTP call in the test. Below threshold or `score < 80` paths are also asserted to return `None`.

**Automated portion** [integration]
- **File:** `tests/integration_db.rs`
- **Test name:** `ac4_1_pending_artist_transitions_to_done`
- **Verifies:** Wires a stub `ArtistEnricher` that returns a hardcoded `EnrichmentResult` (canonical_name + external_id + tags). Creates a PENDING artist via event upsert, runs `EnrichmentOrchestrator::enrich_batch`, and asserts the artist is now `EnrichmentStatus::Done` with `canonical_name`, `musicbrainz_id`, and `mb_tags` populated. Exercises the full `claim_pending_batch → mark IN_PROGRESS → run enricher → MergedResult::apply → save with DONE` path.

**Human verification portion**
- **Justification:** The above tests do not exercise the live MusicBrainz HTTP surface — only the parser and the orchestrator state machine. Whether the connector successfully talks to `https://musicbrainz.org/ws/2/artist/` with the configured user-agent and rate limit cannot be verified without network and live API behavior, which is out of scope for repeatable CI tests.
- **Procedure:**
  1. With `just dev` running and `ENRICHMENT_ENABLED=true`, manually upsert an event whose artist is a well-known DC act (e.g., "Fugazi") via a test seed or by adding a fixture.
  2. Wait for the next enrichment cron tick (or trigger manually by setting `ENRICHMENT_CRON` to fire imminently and restarting the server).
  3. Query the database: `SELECT name, canonical_name, musicbrainz_id, enrichment_status, array_length(mb_tags, 1) FROM artists WHERE name = 'Fugazi'`.
  4. Confirm `enrichment_status = 'DONE'`, `musicbrainz_id` is a UUID, and `mb_tags` is non-empty.

### rust-port.AC4.2 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `artist_marked_skipped_after_max_attempts`
- **Verifies:** With a `NullEnricher` stub that always returns `Ok(None)`, running `enrich_batch` then `reset_eligible_failed_to_pending(3)` four times causes the artist's `enrichment_status` to become `Skipped` because `enrichment_attempts` exceeds `max_attempts = 3`. Already specified in Phase 6 Task 5.

### rust-port.AC4.3 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `startup_reset_clears_in_progress`
- **Verifies:** After claiming a batch (which marks artists `IN_PROGRESS`), calling `EnrichmentOrchestrator::reset_orphaned()` reverts them to `PENDING`. Asserts `find_all` returns zero artists in `IN_PROGRESS` state afterwards. Already specified in Phase 6 Task 5; mirrors the startup behavior wired in `main.rs` per Phase 6 Task 4.

### rust-port.AC4.4 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `transient_error_marks_failed_not_skipped`
- **Verifies:** With an `ErrorEnricher` stub that always returns `Err(EnrichmentError::Api(...))`, running `enrich_batch` once causes the artist to transition to `EnrichmentStatus::Failed` (NOT `Skipped`), leaving it eligible for `reset_eligible_failed_to_pending` on the next cycle. Already specified in Phase 6 Task 5.

### rust-port.AC4.5 [automated]
- **Type:** unit
- **File:** `src/adapters/enrichers/spotify.rs` (inline `#[cfg(test)] mod tests`)
- **Test name:** `spotify_enricher_disabled_when_flag_off`
- **Verifies:** `SpotifyEnricher::new(client, &config)` returns `None` when `config.spotify_enabled == false`, and returns `Some(_)` only when `spotify_enabled == true` AND both `spotify_client_id` and `spotify_client_secret` are populated. Uses `Config::test_default()` (which sets `spotify_enabled = false`) as the negative case. Already specified in Phase 6 Task 6 Step 3.

---

## rust-port.AC5: Admin API and HTTP Basic auth

### rust-port.AC5.1 [automated]
- **Type:** unit (handler)
- **File:** `tests/api.rs`
- **Test name:** `admin_valid_credentials_returns_200`
- **Verifies:** `GET /api/admin/sources` with `Authorization: Basic <base64(testuser:testpass)>` returns HTTP 200 and a JSON array (possibly empty when using `EmptySourceRepository`). For full schema verification of the `last_success_at`, `consecutive_failures`, `healthy` fields, an integration test (`ac5_1_admin_sources_returns_health_fields` in `tests/integration_db.rs`) seeds a source via `pg_sources` and asserts the JSON shape.

### rust-port.AC5.2 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac5_2_source_history_ordered_desc`
- **Verifies:** Inserts three `ingestion_runs` rows for one source (with monotonically increasing `started_at`), then calls `GET /api/admin/sources/{id}/history` with valid Basic auth and asserts the response array is in DESC order by `started_at`. Exercises `pg_ingestion_runs::find_by_source_id_desc` from Phase 3 Task 2.

### rust-port.AC5.3 [automated]
- **Type:** integration
- **File:** `tests/integration_db.rs`
- **Test name:** `ac5_3_create_featured_returns_created`
- **Verifies:** With a seeded event in the DB, `POST /api/admin/featured` with body `{"event_id": "<uuid>", "blurb": "Pick of the week"}` and valid Basic auth returns HTTP 201 with a `FeaturedEventDto` containing the blurb. Asserts a row in `featured_events` exists post-call. Per Phase 4 Task 4.

### rust-port.AC5.4 [automated]
- **Type:** unit (handler)
- **File:** `tests/api.rs`
- **Test name:** `admin_without_auth_returns_401`
- **Verifies:** `GET /api/admin/sources` without an `Authorization` header returns HTTP 401. The `require_basic_auth` middleware reads the raw header, sees it is missing, and returns `ApiError::Unauthorized` → 401. Already specified in Phase 4 Task 6.

### rust-port.AC5.5 [automated]
- **Type:** unit (handler)
- **File:** `tests/api.rs`
- **Test name:** `admin_wrong_credentials_returns_401`
- **Verifies:** `GET /api/admin/sources` with `Authorization: Basic <base64(wrong:creds)>` returns HTTP 401. The middleware decodes the credentials and compares against `Config.admin_username`/`admin_password`, returning `ApiError::Unauthorized` on mismatch. Already specified in Phase 4 Task 6.

### rust-port.AC5.6 [automated]
- **Type:** unit (handler)
- **File:** `tests/api.rs`
- **Test name:** `create_featured_blank_blurb_returns_400`
- **Verifies:** `POST /api/admin/featured` with a body whose `blurb` field is `""` or whitespace-only returns HTTP 400 with body `{"error":"blurb cannot be blank"}`. The handler `admin::create_featured` in Phase 4 Task 4 short-circuits on `body.blurb.trim().is_empty()`.

### rust-port.AC5.7 [automated]
- **Type:** unit (handler)
- **File:** `tests/api.rs`
- **Test name:** `create_featured_unknown_event_returns_404`
- **Verifies:** `POST /api/admin/featured` with `event_id` set to a UUID not present in the DB returns HTTP 404. The handler calls `state.events.find_by_id(EventId(body.event_id))`; the `EmptyEventRepository` fake returns `RepoError::NotFound`, which maps to HTTP 404. The full integration version of this test (`ac5_7_create_featured_unknown_event_returns_404` in `tests/integration_db.rs`) uses real adapters and a randomly-generated UUID.

---

## rust-port.AC6: Frontend pages

### rust-port.AC6.1 [automated]
- **Type:** build (treat as smoke test)
- **File:** N/A — build command output
- **Test name (CI step):** `frontend_build_clean`
- **Verifies:** `cd frontend && pnpm build` exits with status 0 and produces `dist/index.html`, `dist/src/pages/ingestion/index.html`, `dist/src/pages/featured/index.html`, plus their `.js` chunks under `dist/assets/`. The tsc strict mode enforced by the project's `tsconfig.json` means any TypeScript error fails the build. Run as a step in `just check` extension or invoked explicitly in CI; the existing `scripts/dev.sh` already runs `pnpm build`.

### rust-port.AC6.2 [human]
- **Justification:** Verifying that DOM nodes are rendered (source health cards present, classes set correctly, badges colored according to `healthy` flag) requires a real browser and DOM inspection. The project does not include a JS test runner, jsdom, Playwright, or any browser-automation dependency by design (Phase 7 explicitly states: no hot reload, no `vite dev`/`vite preview`, no JS test infrastructure). Adding browser automation just for this one assertion is disproportionate.
- **Procedure:**
  1. Run `just dev` on the host to bring up the kind cluster, Postgres, and the Rust server.
  2. Manually insert at least 2 sources into the `sources` table with differing `healthy` values (or rely on the seed migration data plus a manual `UPDATE sources SET consecutive_failures = 5, healthy = false WHERE name = 'dc9'`).
  3. Open `http://localhost:8080/src/pages/ingestion/` in a browser.
  4. Log in with `admin` / `changeme`.
  5. Confirm a grid of source cards renders, one per source. Each card displays the source name, type, last success timestamp, consecutive failures count, and a badge that reads "Healthy" (green) or "N failures" (red). Confirm the `class` toggles between `source-card healthy` and `source-card unhealthy` accordingly.

### rust-port.AC6.3 [human]
- **Justification:** Verifying click-through behavior — that clicking a per-source "Trigger" button calls `POST /api/admin/ingest/trigger/{source_id}` and that the displayed status updates afterwards — requires both a live server (so the trigger has somewhere to POST) and a live DOM (to confirm the visual update). Same rationale as AC6.2.
- **Procedure:**
  1. From the ingestion page (logged in per AC6.2), click "Trigger" on any source card.
  2. Confirm the button text changes to "Running..." and is disabled while the request is in flight.
  3. Confirm the entire grid re-renders after the request completes (this is `renderApp` being called in the `onTrigger` callback).
  4. Open browser DevTools → Network tab and verify a `POST /api/admin/ingest/trigger/{source_id}` request was made with status 200.
  5. Optionally inspect the `ingestion_runs` table via `just psql` to verify a new row appeared.

### rust-port.AC6.4 [human]
- **Justification:** Same as AC6.2 — verifying form submission and history list rendering requires live browser interaction.
- **Procedure:**
  1. With `just dev` running, insert at least one event and capture its UUID: `just psql -c "SELECT id FROM events LIMIT 1;"`.
  2. Open `http://localhost:8080/src/pages/featured/` in a browser, log in.
  3. Confirm a "Create New Featured Event" form is visible and a "History" section exists below.
  4. Paste the event UUID into the Event UUID field, type a non-empty blurb, click "Create Featured Event".
  5. Confirm the page re-renders and the new entry appears in the History list with the correct title, blurb, and `created_by = "admin"`.
  6. Submit the form again with a blank blurb; confirm an inline error message appears and the form does NOT submit.

---

## rust-port.AC7: Test coverage

### rust-port.AC7.1 [automated]
- **Type:** meta (test suite execution)
- **File:** `tests/connector_tests.rs`
- **Test name:** all 11 tests listed under AC3.1
- **Verifies:** Running `just test` invokes `cargo test --workspace` (and `bazel test //tests:connector_tests` under Bazel) which executes every test in `tests/connector_tests.rs`. CI passes only if all connector fixture tests pass. Equivalently, `bazel test //tests:connector_tests` exits 0.

### rust-port.AC7.2 [automated]
- **Type:** property
- **File:** `tests/properties.rs`
- **Test names:** `slug_is_non_empty_for_valid_input`, `slug_is_url_safe`, `normalization_preserves_start_time`
- **Verifies:** `proptest` generates 256 (default) random `(title, venue, start_time)` triples per test and asserts the invariants hold for all. Verifies `generate_slug` always produces a non-empty URL-safe string and that `NormalizationService::normalize` does not mutate `start_time`. Already specified in Phase 5 Task 9.

### rust-port.AC7.3 [automated]
- **Type:** property
- **File:** `tests/properties.rs`
- **Test name:** `deduplication_is_idempotent`
- **Verifies:** For arbitrary lists of `NormalizedEvent`s, `deduplicate(deduplicate(xs))` yields the same slug set as `deduplicate(xs)` — the second pass cannot produce further merges. Already specified in Phase 5 Task 9.

### rust-port.AC7.4 [automated]
- **Type:** lint
- **File:** N/A — `just check` target
- **Test name (CI step):** `just_check_passes`
- **Verifies:** `just check` runs `cargo fmt --check` and `cargo clippy --all-targets -- -D warnings`. Both must pass for the build to be green. This is the single canonical pre-commit gate per `Justfile` and `CLAUDE.md`. Phase verification steps in every phase end with running this command.

---

## Human Verification Checklist

The following items must be verified by a human before the Rust port is considered complete. None of these should block CI; all are run manually during release verification.

| AC | Description | Rationale |
|---|---|---|
| rust-port.AC4.1 | A real PENDING artist transitions to DONE after live MusicBrainz enrichment, with non-stub canonical name + MBID + tags. | Live external HTTP API; not deterministic enough for CI. |
| rust-port.AC6.2 | Ingestion monitor renders source health cards with correct color coding. | Browser DOM rendering; no JS test infrastructure in scope. |
| rust-port.AC6.3 | Manual trigger button calls API and refreshes the grid. | Browser click → fetch → re-render path; same rationale. |
| rust-port.AC6.4 | Featured events page renders history and accepts new submissions. | Same rationale. |

### Manual verification session checklist

Before tagging a release, run through this list once on a fresh checkout with `just dev` running:

- [ ] AC4.1 live enrichment: insert an event with a known artist, wait for cron tick, verify DB row.
- [ ] AC6.1 build: `cd frontend && pnpm build` exits 0 with all three HTML bundles in `dist/`.
- [ ] AC6.2 ingestion page: source cards render with correct health/badge state.
- [ ] AC6.3 ingestion trigger: click triggers a POST and the grid refreshes.
- [ ] AC6.4 featured admin: create and history list both work; blank-blurb shows inline error.
- [ ] Smoke test public API: `curl http://localhost:8080/api/events` returns paginated JSON.
- [ ] Smoke test admin API: `curl -u admin:changeme http://localhost:8080/api/admin/sources` returns 200.

Once every item above is checked and `just check && just test && just test-integration` all pass on CI with a fresh database, the port satisfies the Definition of Done.
