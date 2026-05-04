# Implementation Plan Guidance — districtlive-server

Project-specific standards for code reviewers. Apply these on top of generic code quality checks.

## Definition of Done

A task is complete only when ALL of the following pass:

```bash
just check     # cargo fmt --check + cargo clippy -D warnings + bazel test //...
```

For any task that adds or changes SQL queries:
```bash
cargo sqlx prepare   # regenerates .sqlx/ offline cache
```

The `.sqlx/` directory must be committed. Never leave it stale.

## Rust Conventions

### Dependency pinning
ALL `Cargo.toml` dependencies must use exact version pins — no caret (`^`) or tilde (`~`) ranges:

```toml
# CORRECT
axum = "=0.8.9"
tokio = { version = "=1.52.1", features = [...] }

# WRONG — reject these
axum = "0.8"
tokio = "^1"
```

Flag any new or changed dependency that doesn't use the `=x.y.z` form.

### Lint suppressions
Use `#[expect(...)]` instead of `#[allow(...)]`. The `expect` form warns when the suppression is no longer needed:

```rust
// CORRECT
#[expect(dead_code)]
fn unused_for_now() {}

// WRONG
#[allow(dead_code)]
fn unused_for_now() {}
```

### Error types
- Domain layer (`src/domain/`): no `anyhow`. Use typed errors with `thiserror`.
- Repository layer: `RepoError`
- Ingestion layer: `IngestionError`
- Enrichment layer: `EnrichmentError`
- `anyhow` is allowed only in adapters and the main binary where error propagation doesn't cross a port boundary.

### No unwrap in non-test code
`unwrap()` and `expect()` (the `Option`/`Result` methods, not the attribute) are forbidden outside `#[cfg(test)]` blocks and test files. Use `?`, `map_err`, or explicit match.

### Architecture boundaries (hexagonal)
- `src/domain/` — pure value types and business logic. Zero I/O. No sqlx, no reqwest, no tokio I/O primitives.
- `src/ports/` — async trait interfaces only. No implementations.
- `src/adapters/` — implement ports. All database calls, HTTP calls, and file I/O live here.
- `src/http/` — thin handlers: extract → call adapter → map to DTO → respond. No SQL, no business logic.
- HTTP handlers must never call `sqlx` directly. They go through ports injected into `AppState`.

### DTOs
- `EventDto::from_event()` is the single conversion point from domain Event to HTTP response. Don't add parallel conversion paths.
- `ArtistDto` must not expose enrichment internals (`enrichment_status`, `mb_tags`, etc.). Consumer-facing fields only.
- Domain types are never serialized directly to HTTP responses.

### Source file markers
Each source file should carry one of:
```rust
// pattern: Functional Core
// pattern: Imperative Shell
```
New files must include the appropriate marker.

## Kubernetes / kustomize Conventions

- **Never edit existing files in `k8s/base/`**. Base manifests are shared across all environments.
- Overlays go in `k8s/overlays/<env>/`. Each overlay contains a `kustomization.yaml` and patch files.
- Use strategic merge patches (`.yaml` patch files) or JSON patches (`patchesJson6902`) — never duplicate entire base resources.
- Storage class for DOKS is `do-block-storage`. Verify any PVC patches use this value, not `standard` or `hostpath`.
- `imagePullSecrets` must be added via the overlay, never baked into the base.

## GitHub Actions Conventions

- Mirror the toolchain versions from `.github/workflows/ci.yml` exactly: Bazelisk (`bazelbuild/setup-bazelisk@v3`), pnpm 10, Node 22.
- The deploy workflow must not run `cargo` or `rustup` directly — Bazel manages the Rust toolchain hermetically.
- Use `workflow_run` trigger (not `push`) so deploy only fires after CI passes.
- Secrets referenced in workflow files must be documented in `docs/staging-setup.md` with their expected values.
- Docker image tags must use the git SHA (`${{ github.sha }}`), never `latest`.

## Documentation Conventions

- Runbooks in `docs/` are written for a developer who has never touched this project before.
- Shell commands in runbooks must be copy-pasteable with no silent prerequisites. State every prerequisite tool explicitly.
- Runbook steps that require manual browser interaction (e.g., DigitalOcean dashboard) must name the exact UI path.
