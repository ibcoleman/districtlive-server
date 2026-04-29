use async_trait::async_trait;
use sqlx::PgPool;
use std::sync::Arc;
use time::OffsetDateTime;

use crate::domain::{
    error::RepoError,
    event::EventId,
    featured_event::{FeaturedEvent, FeaturedEventId},
};
use crate::ports::FeaturedEventRepository;

#[derive(Clone)]
pub struct PgFeaturedEventRepository {
    pool: Arc<PgPool>,
}

impl PgFeaturedEventRepository {
    pub fn new(pool: Arc<PgPool>) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl FeaturedEventRepository for PgFeaturedEventRepository {
    async fn find_current(&self) -> Result<Option<FeaturedEvent>, RepoError> {
        let row = sqlx::query_as::<_, FeaturedEventRow>(
            r#"SELECT id, event_id, blurb, created_at, created_by
               FROM featured_events
               ORDER BY created_at DESC
               LIMIT 1"#,
        )
        .fetch_optional(&*self.pool)
        .await?;
        Ok(row.map(FeaturedEvent::from))
    }

    async fn find_all_desc(&self) -> Result<Vec<FeaturedEvent>, RepoError> {
        let rows = sqlx::query_as::<_, FeaturedEventRow>(
            r#"SELECT id, event_id, blurb, created_at, created_by
               FROM featured_events ORDER BY created_at DESC"#,
        )
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(FeaturedEvent::from).collect())
    }

    async fn find_by_id(&self, id: FeaturedEventId) -> Result<FeaturedEvent, RepoError> {
        sqlx::query_as::<_, FeaturedEventRow>(
            r#"SELECT id, event_id, blurb, created_at, created_by
               FROM featured_events WHERE id = $1"#,
        )
        .bind(id.0)
        .fetch_optional(&*self.pool)
        .await?
        .map(FeaturedEvent::from)
        .ok_or(RepoError::NotFound)
    }

    async fn save(&self, featured: &FeaturedEvent) -> Result<FeaturedEvent, RepoError> {
        sqlx::query(
            r#"INSERT INTO featured_events (id, event_id, blurb, created_at, created_by)
               VALUES ($1, $2, $3, $4, $5)"#,
        )
        .bind(featured.id.0)
        .bind(featured.event_id.0)
        .bind(&featured.blurb)
        .bind(featured.created_at)
        .bind(&featured.created_by)
        .execute(&*self.pool)
        .await?;
        self.find_by_id(featured.id).await
    }
}

// ---- Row type for sqlx deserialization ----

#[derive(sqlx::FromRow)]
struct FeaturedEventRow {
    id: uuid::Uuid,
    event_id: uuid::Uuid,
    blurb: String,
    created_at: OffsetDateTime,
    created_by: String,
}

impl From<FeaturedEventRow> for FeaturedEvent {
    fn from(r: FeaturedEventRow) -> Self {
        FeaturedEvent {
            id: FeaturedEventId(r.id),
            event_id: EventId(r.event_id),
            blurb: r.blurb,
            created_at: r.created_at,
            created_by: r.created_by,
        }
    }
}
