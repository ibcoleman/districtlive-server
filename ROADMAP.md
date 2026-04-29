# Roadmap

High-level "get to it eventually" list. Items here are intentionally rough — promote to `docs/design-plans/` when ready to flesh out.

## Future work

- **FE/BE type-safety via OpenAPI codegen.** Annotate Axum handlers with [`utoipa`](https://docs.rs/utoipa) so the Rust backend emits an OpenAPI spec at build time. On the frontend, generate a typed client and Zod schemas from the spec via [`openapi-zod-client`](https://github.com/astahmer/openapi-zod-client) (or `orval`). Result: backend is the single source of truth for API shapes; frontend gets runtime validation at the boundary plus static types that fail `tsc` the moment the server drifts. Lighter alternative if Zod feels heavy: [`ts-rs`](https://docs.rs/ts-rs) for types-only codegen.
