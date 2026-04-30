# Enrichment Pipeline

Last verified: 2026-04-30

## Purpose
Runs background metadata enrichment for artists discovered during ingestion.
Fetches canonical names, MusicBrainz IDs, Spotify IDs, genres, and images from external APIs.

## Contracts
- **Exposes**: `EnrichmentOrchestrator::new(artists, enrichers)`, `enrich_batch() -> Result<usize>`, `reset_orphaned() -> Result<()>`; `start_enrichment_scheduler(config, orchestrator) -> Result<JobScheduler>`
- **Guarantees**: State machine — artists transition PENDING → IN_PROGRESS (claimed) → DONE | FAILED | SKIPPED. `reset_orphaned()` is always called at startup (even when `ENRICHMENT_ENABLED=false`) to recover from crashes. FAILED artists with attempts < max_attempts are reset to PENDING on startup for retry.
- **Expects**: `ArtistRepository` with `claim_pending_batch`, `reset_in_progress_to_pending`, `reset_eligible_failed_to_pending`. Enrichers implement `ArtistEnricher` port.

## Dependencies
- **Uses**: `src/ports::ArtistRepository`, `src/ports::ArtistEnricher`, `src/domain::artist::{Artist, EnrichmentStatus, EnrichmentResult}`
- **Used by**: `src/main.rs` (spawns scheduler and orphan reset at startup)
- **Boundary**: No HTTP handlers here; no direct sqlx. Only port traits.

## Key Decisions
- MusicBrainz rate limit: 1100ms sleep between each artist (`DEFAULT_RATE_LIMIT_MS`). Do not remove.
- MergedResult accumulates across all enrichers before writing — single `save()` call per artist.
- `apply()` on MergedResult routes fields by `EnrichmentSource` enum, not heuristics.
- Orphan reset runs unconditionally at startup (separate from ENRICHMENT_ENABLED guard).

## Invariants
- `enrichment_attempts` is always incremented on every transition, regardless of outcome.
- Artists are only moved to SKIPPED when `enrichment_attempts >= max_attempts` (default 3) AND no enricher succeeded.
- `transition()` receives the full `Artist` struct directly — no re-fetch — to avoid TOCTOU.

## Key Files
- `orchestrator.rs` — state machine and batch processing
- `scheduler.rs` — cron job wiring

## Gotchas
- SKIPPED threshold is checked against `enrichment_attempts` on the Artist passed in, not re-fetched. Order matters.
- Spotify enricher is optional (returns `None` from `new()` if credentials absent) — check before pushing to enricher vec.
