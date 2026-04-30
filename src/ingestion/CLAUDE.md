# Ingestion Pipeline

Last verified: 2026-04-30

## Purpose
Fetches raw event data from external sources (APIs and venue scrapers), normalizes it,
deduplicates against existing events, and upserts into the database.

## Contracts
- **Exposes**: `IngestionOrchestrator::new(events, ingestion_runs, sources)`, `run_connector(connector) -> Result<IngestionStats>`; `start_ingestion_scheduler(config, orchestrator, api_connectors, scraper_connectors) -> Result<JobScheduler>`
- **Guarantees**: Each connector run opens an `IngestionRun` record, records stats on completion, and marks source health. `IngestionStats` counts fetched/created/updated/deduplicated events.
- **Expects**: Connectors implement `SourceConnector` port. Repos implement their respective port traits.

## Dependencies
- **Uses**: `src/ports::{EventRepository, IngestionRunRepository, SourceRepository, SourceConnector}`, `src/domain::event::EventUpsertCommand`
- **Used by**: `src/main.rs` (spawns two cron schedules: api + scraper), `src/http/admin.rs` (trigger endpoint)
- **Boundary**: No HTTP logic here. Connectors are in `src/adapters/connectors/`.

## Key Decisions
- Two separate cron schedules: `INGESTION_API_CRON` (Ticketmaster, Bandsintown, Dice.fm) and `INGESTION_SCRAPER_CRON` (7 venue scrapers). Default both to every 6 hours, offset by 30 minutes.
- Connectors are conditionally built: API connectors only when their API key env var is set.
- Scraper connectors are always built (no credentials needed).

## Invariants
- All 7 venue scrapers are instantiated unconditionally in `build_connectors()` in `main.rs`.
- `trigger_source_ingestion` endpoint accepts `Path<Uuid>` (not `Path<String>`) — enforced type safety.

## Key Files
- `orchestrator.rs` — pipeline: fetch → normalize → deduplicate → upsert
- `scheduler.rs` — cron wiring for api and scraper batches
- `normalization.rs` — NormalizationService
- `deduplication.rs` — DeduplicationService

## Gotchas
- Ingestion only runs when `INGESTION_ENABLED=true`. Scheduler is not spawned otherwise.
- `run_connector` is also called from the admin trigger endpoint (same codepath as scheduled runs).
