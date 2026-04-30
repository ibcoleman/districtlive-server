# Roadmap

High-level "get to it eventually" list. Items here are intentionally rough — promote to `docs/design-plans/` when ready to flesh out.

## Future work
- [ ] Test just & jj hook in Innie Claude
- [ ] I can run `just dev` and hit the local server; Can run an ingest and populate local db
- [ ] I can push the k8s cluster to GitHub or DO and deploy it
- [ ] I can hit the ingest API and populate the DO database.
- [ ] Push configuration for jj hook back into rust-app-template so it works on Innie Claude projects
- [ ] **FE/BE type-safety via OpenAPI codegen.** Annotate Axum handlers with [`utoipa`](https://docs.rs/utoipa) so the Rust backend emits an OpenAPI spec at build time. On the frontend, generate a typed client and Zod schemas from the spec via [`openapi-zod-client`](https://github.com/astahmer/openapi-zod-client) (or `orval`). Result: backend is the single source of truth for API shapes; frontend gets runtime validation at the boundary plus static types that fail `tsc` the moment the server drifts. Lighter alternative if Zod feels heavy: [`ts-rs`](https://docs.rs/ts-rs) for types-only codegen.
