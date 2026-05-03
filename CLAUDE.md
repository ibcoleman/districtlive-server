# districtlive-server

Last verified: 2026-04-30

## Quick Start: Where to Begin

### New feature (touches multiple files or involves architectural decisions)
1. **Opus** — `/start-design-plan` (describe the idea; Claude will clarify, investigate, and brainstorm options)
2. `/clear`
3. **Sonnet** — `/start-implementation-plan @docs/design-plans/YYYY-MM-DD-feature.md`
4. `/clear`
5. **Sonnet** — `/execute-implementation-plan @docs/implementation-plans/YYYY-MM-DD-feature/`

### New feature (small — you know exactly what to change, ≤ a few files)
Skip the workflow. Just implement it directly. No ceremony needed.

### Rough idea (not sure what to build yet, or need to think it through)
- **Opus** — `/flesh-it-out` — clarifies and sharpens the idea before any design work starts
- Then proceed to `/start-design-plan` when ready

### Bug fix
- **Opus** — `/systematic-debugging` first — finds root cause before proposing a fix
- Small fix: implement directly after diagnosis
- Larger fix (multiple files, uncertain blast radius): run a mini `/start-design-plan` cycle

### New project (greenfield)
1. **Opus** — `/flesh-it-out` — settle what you're actually building
2. **Opus** — `/start-design-plan` — architecture and phases
3. Continue with plan → execute as above

### Reviewing work
- After a task: **Sonnet** — `/requesting-code-review`
- After a session: **Haiku/Sonnet** — `/review-session`
- After several sessions: **Sonnet** — `/review-recent-sessions`

### Model quick-reference
| Work type | Model |
|---|---|
| Design, architecture, brainstorming, debugging | **Opus** |
| Implementation, planning, code review, tests | **Sonnet** |
| File searches, grep, log scanning, lookups | **Haiku** |

### Other useful skills (invoke anytime)
| Skill | When to use |
|---|---|
| `/brainstorming` | Standalone brainstorm, not committing to a design yet |
| `/asking-clarifying-questions` | Standalone clarification pass |
| `/retrospective` | When a dev attempt hit a dead end |
| `/how-to-customize` | Understand `.ed3d/` guidance files |

## Tech Stack
- Language: Rust (edition 2021)
- Web framework: Axum
- Database: PostgreSQL via sqlx (compile-time checked queries)
- Build: Cargo (primary), Bazel (CI targets in BUILD.bazel)
- Task runner: `just` (Justfile)
- Frontend: TypeScript + Vite (multi-entry), embedded in binary via rust-embed
- Testing: cargo test + integration tests requiring live Postgres

## Commands
- `just check` — cargo clippy + fmt check
- `just test` — unit tests (no Postgres required)
- `just test-integration` — integration tests (requires `DATABASE_URL`)
- `just build` — release build
- `cargo sqlx prepare` — regenerate `.sqlx/` offline query cache after SQL changes

## Project Structure
- `src/domain/` — pure value types, no I/O (Artist, Event, Venue, etc.)
- `src/ports/` — async trait interfaces between domain and infrastructure
- `src/adapters/` — concrete port implementations (Postgres, HTTP enrichers, scrapers)
- `src/enrichment/` — enrichment orchestrator + cron scheduler
- `src/ingestion/` — ingestion orchestrator + cron scheduler + connectors
- `src/http/` — Axum router, handlers, DTOs, middleware
- `src/config.rs` — environment-variable configuration
- `migrations/` — immutable sqlx migration files (never edit existing)
- `frontend/` — TypeScript SPA, compiled into `frontend/dist/` and embedded
- `tests/` — integration tests (require live Postgres)
- `docs/design-plans/` and `docs/implementation-plans/` — design artifacts

## Architecture
Hexagonal / ports-and-adapters:
- Domain core (`src/domain/`) has no I/O
- Ports (`src/ports/`) define async trait interfaces
- Adapters implement ports and are injected into `AppState` at startup
- HTTP handlers are thin: extract → call adapter → map to DTO → respond

## Conventions
- Error types: `RepoError` (repository layer), `IngestionError`, `EnrichmentError` — no raw `anyhow` in domain
- DTOs live in `src/http/dto.rs`; domain types are never serialized directly to HTTP responses
- `EventDto::from_event()` is the single conversion point; hydrate venue/artists separately after
- `ArtistDto` omits enrichment internals (no `enrichment_status`, `mb_tags`, etc.) — only consumer-facing fields
- Functional Core / Imperative Shell: pure logic in domain, side effects in adapters/schedulers
- `// pattern: Imperative Shell` or `// pattern: Functional Core` comment marks each source file
- Use `#[expect(...)]` instead of `#[allow(...)]` for lint suppressions — it warns when the suppression is no longer needed
- All `Cargo.toml` dependencies use exact `=x.y.z` version pins (no caret or tilde ranges) — deliberate for reproducibility

## Key Environment Variables
| Variable | Required | Default | Purpose |
|---|---|---|---|
| `DATABASE_URL` | yes | — | Postgres connection string |
| `BIND_ADDR` | no | `0.0.0.0:8080` | HTTP listen address |
| `ADMIN_USERNAME` / `ADMIN_PASSWORD` | no | `admin`/`changeme` | Basic auth for `/api/admin/*` |
| `INGESTION_ENABLED` | no | `false` | Start ingestion scheduler |
| `ENRICHMENT_ENABLED` | no | `false` | Start enrichment scheduler |
| `TICKETMASTER_API_KEY` | no | — | Enables Ticketmaster connector |
| `BANDSINTOWN_APP_ID` | no | — | Enables Bandsintown connector |
| `DICEFM_VENUE_SLUGS` | no | — | Comma-separated Dice.fm venue slugs |
| `SPOTIFY_CLIENT_ID` / `SPOTIFY_CLIENT_SECRET` | no | — | Enables Spotify enricher |
| `MUSICBRAINZ_CONFIDENCE_THRESHOLD` | no | `0.7` | Jaro-Winkler match threshold |

## Boundaries
- Safe to edit: `src/`, `frontend/src/`, `migrations/` (add new only)
- Never edit: existing migration files, `.sqlx/` cache (regenerate via `cargo sqlx prepare`)
- Never touch: `Cargo.lock` without reason (committed, intentional)
