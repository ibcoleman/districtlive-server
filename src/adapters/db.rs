//! Database connection pool creation and migration runner.

use sqlx::{postgres::PgPoolOptions, PgPool};

/// Create a PostgreSQL connection pool and run pending migrations.
///
/// Call once at application startup. Pass the returned pool to each adapter constructor.
pub async fn connect(database_url: &str) -> anyhow::Result<PgPool> {
    let pool = PgPoolOptions::new()
        .max_connections(8)
        .connect(database_url)
        .await
        .map_err(|e| anyhow::anyhow!("Failed to connect to database: {e}"))?;

    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .map_err(|e| anyhow::anyhow!("Failed to run migrations: {e}"))?;

    Ok(pool)
}

#[cfg(feature = "test-helpers")]
pub struct TestHelper {
    pool: std::sync::Arc<sqlx::PgPool>,
}

#[cfg(feature = "test-helpers")]
impl TestHelper {
    pub fn new(pool: std::sync::Arc<sqlx::PgPool>) -> Self {
        Self { pool }
    }

    /// Truncate all domain tables in FK-safe order. Call before each integration test.
    ///
    /// IMPORTANT: `venues` and `sources` are intentionally excluded from truncation.
    /// These tables contain seed data inserted by migrations (V8, V9, V11, V14-V20).
    /// Truncating them would destroy seed data that tests like `ac1_3_seed_data_present`
    /// depend on. Integration tests that need a clean venue/source slate should explicitly
    /// truncate those tables in their own setup, not via this helper.
    pub async fn reset(&self) {
        sqlx::query(
            "TRUNCATE featured_events, event_sources, event_artists, events, ingestion_runs, artists CASCADE"
        )
        .execute(&*self.pool)
        .await
        .expect("Failed to reset test database");
    }
}
