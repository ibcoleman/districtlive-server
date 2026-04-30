// pattern: Imperative Shell
use async_trait::async_trait;
use sqlx::PgPool;
use std::sync::Arc;
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::{
    error::RepoError,
    ingestion_run::{IngestionRun, IngestionRunId, IngestionRunStatus},
    source::SourceId,
};
use crate::ports::IngestionRunRepository;

#[derive(Clone)]
pub struct PgIngestionRunRepository {
    pool: Arc<PgPool>,
}

impl PgIngestionRunRepository {
    pub fn new(pool: Arc<PgPool>) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl IngestionRunRepository for PgIngestionRunRepository {
    async fn create(
        &self,
        source_id: crate::domain::source::SourceId,
    ) -> Result<IngestionRun, RepoError> {
        let id = Uuid::new_v4();
        let row = sqlx::query_as::<_, IngestionRunRow>(
            r#"INSERT INTO ingestion_runs (id, source_id, started_at)
               VALUES ($1, $2, now())
               RETURNING id, source_id, status, events_fetched, events_created,
                         events_updated, events_deduplicated, error_message, started_at, completed_at"#,
        )
        .bind(id)
        .bind(source_id.0)
        .fetch_one(&*self.pool)
        .await?;
        Ok(IngestionRun::from(row))
    }

    async fn find_by_source_id_desc(
        &self,
        source_id: SourceId,
    ) -> Result<Vec<IngestionRun>, RepoError> {
        let rows = sqlx::query_as::<_, IngestionRunRow>(
            r#"SELECT id, source_id, status, events_fetched, events_created,
                      events_updated, events_deduplicated, error_message, started_at, completed_at
               FROM ingestion_runs WHERE source_id = $1
               ORDER BY started_at DESC"#,
        )
        .bind(source_id.0)
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(IngestionRun::from).collect())
    }

    async fn mark_success(
        &self,
        id: IngestionRunId,
        events_fetched: i32,
        events_created: i32,
        events_updated: i32,
        events_deduplicated: i32,
    ) -> Result<(), RepoError> {
        sqlx::query(
            r#"UPDATE ingestion_runs
               SET status = 'SUCCESS', events_fetched = $2, events_created = $3,
                   events_updated = $4, events_deduplicated = $5, completed_at = now()
               WHERE id = $1"#,
        )
        .bind(id.0)
        .bind(events_fetched)
        .bind(events_created)
        .bind(events_updated)
        .bind(events_deduplicated)
        .execute(&*self.pool)
        .await?;
        Ok(())
    }

    async fn mark_failed(&self, id: IngestionRunId, error_message: &str) -> Result<(), RepoError> {
        sqlx::query(
            r#"UPDATE ingestion_runs
               SET status = 'FAILED', error_message = $2, completed_at = now()
               WHERE id = $1"#,
        )
        .bind(id.0)
        .bind(error_message)
        .execute(&*self.pool)
        .await?;
        Ok(())
    }
}

// ---- Row type for sqlx deserialization ----

#[derive(sqlx::FromRow)]
struct IngestionRunRow {
    id: uuid::Uuid,
    source_id: uuid::Uuid,
    status: IngestionRunStatus,
    events_fetched: i32,
    events_created: i32,
    events_updated: i32,
    events_deduplicated: i32,
    error_message: Option<String>,
    started_at: OffsetDateTime,
    completed_at: Option<OffsetDateTime>,
}

impl From<IngestionRunRow> for IngestionRun {
    fn from(r: IngestionRunRow) -> Self {
        IngestionRun {
            id: IngestionRunId(r.id),
            source_id: SourceId(r.source_id),
            status: r.status,
            events_fetched: r.events_fetched,
            events_created: r.events_created,
            events_updated: r.events_updated,
            events_deduplicated: r.events_deduplicated,
            error_message: r.error_message,
            started_at: r.started_at,
            completed_at: r.completed_at,
        }
    }
}
