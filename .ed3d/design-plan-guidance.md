# Design Plan Guidance — districtlive-server

Loaded before clarification in `/start-design-plan`. Apply these constraints when proposing and evaluating architectural approaches. Do not propose options that violate these unless explicitly asked.

## Mandatory Architecture: Hexagonal / Ports-and-Adapters

Every design must fit this shape:

```
src/domain/     — pure value types and business logic. Zero I/O.
src/ports/      — async trait interfaces only. No implementations.
src/adapters/   — implement ports. All DB, HTTP, and file I/O live here.
src/http/       — thin Axum handlers: extract → call adapter → map to DTO → respond.
```

- Domain types never cross the HTTP boundary directly. They are mapped to DTOs in `src/http/dto.rs`.
- HTTP handlers never call `sqlx` directly. They go through ports injected into `AppState`.
- New adapters are injected at startup, not constructed inside handlers or services.
- If a design places business logic in a handler or an adapter, that is an architecture violation — flag it.

## Functional Core / Imperative Shell (FCIS)

Pure logic lives in domain. Side effects (DB queries, HTTP calls, timers) live in adapters and schedulers. Every source file should be clearly one or the other. Mark new files with:

```rust
// pattern: Functional Core
// pattern: Imperative Shell
```

## Language and Runtime

- Rust edition 2021
- Async runtime: Tokio (already in the dependency tree — do not introduce alternatives)
- Web framework: Axum (already in use — do not propose actix-web, warp, etc.)
- Database: PostgreSQL via sqlx with compile-time checked queries
- Frontend: TypeScript + Vite, compiled to `frontend/dist/`, embedded in binary via rust-embed

## Error Handling

Typed errors, not raw `anyhow`, in anything that crosses a module boundary:

| Layer | Error type |
|---|---|
| `src/domain/` | Custom typed errors via `thiserror` |
| `src/adapters/` (repository) | `RepoError` |
| `src/ingestion/` | `IngestionError` |
| `src/enrichment/` | `EnrichmentError` |
| Adapters / main binary | `anyhow` acceptable for propagation across boundaries |

`unwrap()` and `expect()` (the method, not the attribute) are forbidden outside `#[cfg(test)]` blocks and test files.

## Dependencies

All `Cargo.toml` dependencies must use exact version pins — `=x.y.z`. No caret or tilde ranges. When proposing new dependencies, note this constraint and flag it if unsure of exact version.

## Migrations

SQL migrations live in `migrations/`. Existing migration files are immutable — never edit them. New schema changes always add a new migration file. After any SQL change, `.sqlx/` must be regenerated via `cargo sqlx prepare` and committed.

## Testing

- Unit tests: `just test` (no Postgres required)
- Integration tests: `just test-integration` (requires `DATABASE_URL`)
- Never hit real external APIs in tests. Use WireMock, stubs, or recorded fixtures.
- Use Testcontainers (or equivalent) for integration tests requiring a real database — not H2 or in-memory substitutes.

## Scope Signals

When estimating scope, prefer designs that:
- Add new adapters over modifying existing domain types
- Add new ports over changing existing port interfaces (existing adapters would need updating)
- Add new migration files over altering existing schema definitions

Changes to `src/ports/` are high-impact — every adapter implementing that trait must be updated. Flag this in the design document when it occurs.
