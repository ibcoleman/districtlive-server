//! Shared test-support module. Fakes and helpers live here.
//!
//! Will be populated in later phases.

// TODO (Phase 3): Add migration integration tests verifying:
// - All 21 migrations apply in sequence without error
// - Schema tables exist with correct structure
// - Seed data is loaded correctly (if any)
// - Migrations are idempotent (second run succeeds without error)
// Until then, migrations are only tested indirectly via HTTP integration tests
// that depend on database state being correct.
