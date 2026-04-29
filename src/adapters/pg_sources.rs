use async_trait::async_trait;
use sqlx::PgPool;
use std::sync::Arc;
use time::OffsetDateTime;

use crate::domain::{
    error::RepoError,
    source::{Source, SourceId, SourceType},
};
use crate::ports::SourceRepository;

#[derive(Clone)]
pub struct PgSourceRepository {
    pool: Arc<PgPool>,
}

impl PgSourceRepository {
    pub fn new(pool: Arc<PgPool>) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl SourceRepository for PgSourceRepository {
    async fn find_by_id(&self, id: SourceId) -> Result<Source, RepoError> {
        sqlx::query_as::<_, SourceRow>(
            r#"SELECT id, name, source_type, configuration, scrape_schedule,
                      last_success_at, last_failure_at, consecutive_failures, healthy,
                      created_at, updated_at
               FROM sources WHERE id = $1"#,
        )
        .bind(id.0)
        .fetch_optional(&*self.pool)
        .await?
        .map(Source::from)
        .ok_or(RepoError::NotFound)
    }

    async fn find_by_name(&self, name: &str) -> Result<Option<Source>, RepoError> {
        let row = sqlx::query_as::<_, SourceRow>(
            r#"SELECT id, name, source_type, configuration, scrape_schedule,
                      last_success_at, last_failure_at, consecutive_failures, healthy,
                      created_at, updated_at
               FROM sources WHERE name = $1"#,
        )
        .bind(name)
        .fetch_optional(&*self.pool)
        .await?;
        Ok(row.map(Source::from))
    }

    async fn find_all(&self) -> Result<Vec<Source>, RepoError> {
        let rows = sqlx::query_as::<_, SourceRow>(
            r#"SELECT id, name, source_type, configuration, scrape_schedule,
                      last_success_at, last_failure_at, consecutive_failures, healthy,
                      created_at, updated_at
               FROM sources ORDER BY name"#,
        )
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(Source::from).collect())
    }

    async fn find_healthy(&self) -> Result<Vec<Source>, RepoError> {
        let rows = sqlx::query_as::<_, SourceRow>(
            r#"SELECT id, name, source_type, configuration, scrape_schedule,
                      last_success_at, last_failure_at, consecutive_failures, healthy,
                      created_at, updated_at
               FROM sources WHERE healthy = true ORDER BY name"#,
        )
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(Source::from).collect())
    }

    async fn record_success(&self, id: SourceId) -> Result<(), RepoError> {
        sqlx::query(
            r#"UPDATE sources
               SET last_success_at = now(), consecutive_failures = 0, healthy = true,
                   updated_at = now()
               WHERE id = $1"#,
        )
        .bind(id.0)
        .execute(&*self.pool)
        .await?;
        Ok(())
    }

    async fn record_failure(&self, id: SourceId, error_msg: &str) -> Result<(), RepoError> {
        sqlx::query(
            r#"UPDATE sources
               SET last_failure_at = now(),
                   consecutive_failures = consecutive_failures + 1,
                   healthy = (consecutive_failures + 1) <= 3,
                   updated_at = now()
               WHERE id = $1"#,
        )
        .bind(id.0)
        .bind(error_msg)
        .execute(&*self.pool)
        .await?;
        Ok(())
    }
}

// ---- Row type for sqlx deserialization ----

#[derive(sqlx::FromRow)]
struct SourceRow {
    id: uuid::Uuid,
    name: String,
    source_type: SourceType,
    configuration: Option<serde_json::Value>,
    scrape_schedule: Option<String>,
    last_success_at: Option<OffsetDateTime>,
    last_failure_at: Option<OffsetDateTime>,
    consecutive_failures: i32,
    healthy: bool,
    created_at: OffsetDateTime,
    updated_at: OffsetDateTime,
}

impl From<SourceRow> for Source {
    fn from(r: SourceRow) -> Self {
        Source {
            id: SourceId(r.id),
            name: r.name,
            source_type: r.source_type,
            configuration: r.configuration,
            scrape_schedule: r.scrape_schedule,
            last_success_at: r.last_success_at,
            last_failure_at: r.last_failure_at,
            consecutive_failures: r.consecutive_failures,
            healthy: r.healthy,
            created_at: r.created_at,
            updated_at: r.updated_at,
        }
    }
}
