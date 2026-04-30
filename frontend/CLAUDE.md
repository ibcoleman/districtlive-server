# Frontend

Last verified: 2026-04-30

## Purpose
TypeScript SPA compiled by Vite and embedded into the Rust binary at build time via rust-embed.
Provides the public event listing page and two admin management pages.

## Contracts
- **Exposes**: `src/api.ts` — typed API client functions returning `ResultAsync<T, ApiError>`; `src/types.ts` — DTO types mirroring `src/http/dto.rs`
- **Guarantees**: `api.ts` functions wrap all responses in neverthrow `ResultAsync`. Admin functions attach `Authorization: Basic ...` from sessionStorage.
- **Expects**: Server at same origin. Admin credentials stored via `storeCredentials(username, password)` before calling admin functions.

## Build
- `pnpm build` from repo root — outputs to `frontend/dist/`
- Multi-entry: `main` (public), `ingestion` (admin), `featured` (admin)
- Must rebuild frontend before `cargo build` when frontend changes

## Dependencies
- **Uses**: `neverthrow` (ResultAsync), `type-fest` (Tagged nominal IDs)
- **Used by**: Rust binary via rust-embed (`frontend/dist/` → embedded `Assets`)
- **Boundary**: No direct database or backend logic. Pure HTTP client.

## Key Decisions
- Nominal ID types (`EventId`, `VenueId`, etc.) via `type-fest` Tagged to prevent accidental ID mixing.
- Credentials stored in sessionStorage (not localStorage) — cleared on tab close.
- `response.json() as T` — type assertion without runtime validation. Server is trusted source of truth.
- neverthrow ESLint rule disabled (TODO: re-enable when project matures — see eslint.config.js).
- Admin HTML pages served by server without Basic auth; auth is purely client-side via sessionStorage for simplicity.

## Invariants
- `types.ts` must mirror `src/http/dto.rs` — any server DTO change requires a matching types.ts change.
- All server-controlled strings rendered into innerHTML must be escaped (XSS risk — see accepted-risk comments in admin pages).

## Key Files
- `src/types.ts` — DTO type definitions (keep in sync with `src/http/dto.rs`)
- `src/api.ts` — all API calls; credential storage
- `src/pages/ingestion/main.ts` — ingestion monitor admin page
- `src/pages/featured/main.ts` — featured events manager admin page
- `vite.config.ts` — multi-entry build config

## Gotchas
- `ArtistDto` in types.ts intentionally omits social URLs (`spotify_url`, `bandcamp_url`, `instagram_url`) compared to the server-side `ArtistDto` — the server does include them. Update types.ts if those fields are needed client-side.
