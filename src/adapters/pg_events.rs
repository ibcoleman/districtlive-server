// pattern: Imperative Shell
use async_trait::async_trait;
use sqlx::{PgPool, QueryBuilder};
use std::sync::Arc;
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::{
    error::RepoError,
    event::{
        AgeRestriction, Event, EventFilters, EventId, EventStatus, EventType, EventUpsertCommand,
        PriceTier,
    },
    event_source::{EventSource, EventSourceId},
    slugify,
    source::{SourceId, SourceType},
    venue::VenueId,
    Page, Pagination,
};
use crate::ports::{event_repository::UpsertResult, EventRepository};

#[derive(Clone)]
pub struct PgEventRepository {
    pool: Arc<PgPool>,
}

impl PgEventRepository {
    pub fn new(pool: Arc<PgPool>) -> Self {
        Self { pool }
    }

    /// Resolve an existing venue by name or create a new one. Returns the venue ID.
    async fn resolve_or_create_venue(
        tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
        name: &str,
        address: Option<&str>,
    ) -> Result<Uuid, RepoError> {
        let id = Uuid::new_v4();
        let slug = slugify(name);
        // RETURNING id always returns the actual persisted row ID — either the newly
        // inserted row's ID or the existing row's ID on conflict.
        let actual_id = sqlx::query_scalar::<_, Uuid>(
            r#"INSERT INTO venues (id, name, slug, address, created_at, updated_at)
               VALUES ($1, $2, $3, $4, now(), now())
               ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name
               RETURNING id"#,
        )
        .bind(id)
        .bind(name)
        .bind(&slug)
        .bind(address)
        .fetch_one(&mut **tx)
        .await?;
        Ok(actual_id)
    }

    /// Resolve an existing artist by name or create a new one. Returns the artist ID.
    async fn resolve_or_create_artist(
        tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
        name: &str,
    ) -> Result<Uuid, RepoError> {
        let id = Uuid::new_v4();
        let slug = slugify(name);
        // RETURNING id always returns the actual persisted row ID — either the newly
        // inserted row's ID or the existing row's ID on conflict.
        let actual_id = sqlx::query_scalar::<_, Uuid>(
            r#"INSERT INTO artists (id, name, slug, genres, is_local, enrichment_status,
                                    enrichment_attempts, created_at, updated_at)
               VALUES ($1, $2, $3, '{}'::text[], false, 'PENDING', 0, now(), now())
               ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name
               RETURNING id"#,
        )
        .bind(id)
        .bind(name)
        .bind(&slug)
        .fetch_one(&mut **tx)
        .await?;
        Ok(actual_id)
    }
}

#[async_trait]
impl EventRepository for PgEventRepository {
    async fn upsert(&self, cmd: EventUpsertCommand) -> Result<UpsertResult, RepoError> {
        let mut tx = self.pool.begin().await?;

        // Resolve venue
        let venue_id =
            Self::resolve_or_create_venue(&mut tx, &cmd.venue_name, cmd.venue_address.as_deref())
                .await?;

        // Resolve artists
        let mut artist_ids = Vec::with_capacity(cmd.artist_names.len());
        for name in &cmd.artist_names {
            let id = Self::resolve_or_create_artist(&mut tx, name).await?;
            artist_ids.push(id);
        }

        // Upsert event — use xmax to detect created vs updated
        let event_id = Uuid::new_v4();
        let row = sqlx::query_as::<_, (Uuid, bool)>(
            r#"INSERT INTO events (
                   id, slug, title, description, start_time, end_time, doors_time,
                   min_price, max_price, price_tier, ticket_url, image_url,
                   age_restriction, status, venue_id, created_at, updated_at
               ) VALUES (
                   $1, $2, $3, $4, $5, $6, $7,
                   $8, $9, $10, $11, $12,
                   $13, 'ACTIVE', $14, now(), now()
               )
               ON CONFLICT (slug) DO UPDATE SET
                   title = EXCLUDED.title,
                   description = COALESCE(EXCLUDED.description, events.description),
                   start_time = EXCLUDED.start_time,
                   end_time = COALESCE(EXCLUDED.end_time, events.end_time),
                   doors_time = COALESCE(EXCLUDED.doors_time, events.doors_time),
                   min_price = COALESCE(EXCLUDED.min_price, events.min_price),
                   max_price = COALESCE(EXCLUDED.max_price, events.max_price),
                   price_tier = COALESCE(EXCLUDED.price_tier, events.price_tier),
                   ticket_url = COALESCE(EXCLUDED.ticket_url, events.ticket_url),
                   image_url = COALESCE(EXCLUDED.image_url, events.image_url),
                   venue_id = EXCLUDED.venue_id,
                   updated_at = now()
               RETURNING id, (xmax::text::int8 <> 0)::bool"#,
        )
        .bind(event_id)
        .bind(&cmd.slug)
        .bind(&cmd.title)
        .bind(cmd.description.as_deref())
        .bind(cmd.start_time)
        .bind(cmd.end_time)
        .bind(cmd.doors_time)
        .bind(cmd.min_price)
        .bind(cmd.max_price)
        .bind(cmd.price_tier)
        .bind(cmd.ticket_url.as_deref())
        .bind(cmd.image_url.as_deref())
        .bind(cmd.age_restriction as AgeRestriction)
        .bind(venue_id)
        .fetch_one(&mut *tx)
        .await?;

        let actual_event_id = row.0;
        let was_updated = row.1;

        // Link artists (idempotent)
        for artist_id in &artist_ids {
            sqlx::query(
                "INSERT INTO event_artists (event_id, artist_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
            )
            .bind(actual_event_id)
            .bind(artist_id)
            .execute(&mut *tx)
            .await?;
        }

        // Upsert event_sources
        for source in &cmd.source_attributions {
            let source_id = Uuid::new_v4();
            sqlx::query(
                r#"INSERT INTO event_sources (id, event_id, source_type, source_identifier,
                                               source_url, confidence_score, source_id, created_at)
                   VALUES ($1, $2, $3, $4, $5, $6, $7, now())
                   ON CONFLICT DO NOTHING"#,
            )
            .bind(source_id)
            .bind(actual_event_id)
            .bind(source.source_type as SourceType)
            .bind(source.source_identifier.as_deref())
            .bind(source.source_url.as_deref())
            .bind(source.confidence_score)
            .bind(source.source_id.map(|id| id.0))
            .execute(&mut *tx)
            .await?;
        }

        tx.commit().await?;

        if was_updated {
            Ok(UpsertResult::Updated)
        } else {
            Ok(UpsertResult::Created)
        }
    }

    async fn find_by_id(&self, id: EventId) -> Result<Event, RepoError> {
        sqlx::query_as::<_, EventRow>(
            r#"SELECT id, title, slug, description,
                      start_time, end_time, doors_time,
                      min_price, max_price, price_tier,
                      ticket_url, on_sale_date, sold_out, ticket_platform, image_url,
                      age_restriction, status, venue_id, title_parsed,
                      event_type, created_at, updated_at
               FROM events WHERE id = $1"#,
        )
        .bind(id.0)
        .fetch_optional(&*self.pool)
        .await?
        .map(Event::from)
        .ok_or(RepoError::NotFound)
    }

    async fn find_by_slug(&self, slug: &str) -> Result<Option<Event>, RepoError> {
        let row = sqlx::query_as::<_, EventRow>(
            r#"SELECT id, title, slug, description,
                      start_time, end_time, doors_time,
                      min_price, max_price, price_tier,
                      ticket_url, on_sale_date, sold_out, ticket_platform, image_url,
                      age_restriction, status, venue_id, title_parsed,
                      event_type, created_at, updated_at
               FROM events WHERE slug = $1"#,
        )
        .bind(slug)
        .fetch_optional(&*self.pool)
        .await?;
        Ok(row.map(Event::from))
    }

    async fn find_all(
        &self,
        filters: EventFilters,
        page: Pagination,
    ) -> Result<Page<Event>, RepoError> {
        // Build dynamic query with optional filters.
        // Base query joins venues for slug/neighborhood filters.
        let mut count_qb = QueryBuilder::new(
            "SELECT COUNT(DISTINCT e.id) FROM events e LEFT JOIN venues v ON v.id = e.venue_id WHERE 1=1"
        );
        let mut qb = QueryBuilder::new(
            r#"SELECT DISTINCT e.id, e.title, e.slug, e.description,
                      e.start_time, e.end_time, e.doors_time,
                      e.min_price, e.max_price, e.price_tier,
                      e.ticket_url, e.on_sale_date, e.sold_out, e.ticket_platform, e.image_url,
                      e.age_restriction, e.status, e.venue_id, e.title_parsed,
                      e.event_type, e.created_at, e.updated_at
               FROM events e
               LEFT JOIN venues v ON v.id = e.venue_id
               WHERE 1=1"#,
        );

        // Apply filters to both count and data queries
        if let Some(from) = &filters.date_from {
            count_qb.push(" AND e.start_time >= ").push_bind(*from);
            qb.push(" AND e.start_time >= ").push_bind(*from);
        }
        if let Some(to) = &filters.date_to {
            count_qb.push(" AND e.start_time <= ").push_bind(*to);
            qb.push(" AND e.start_time <= ").push_bind(*to);
        }
        if let Some(slug) = &filters.venue_slug {
            count_qb
                .push(" AND (v.slug = ")
                .push_bind(slug.clone())
                .push(" OR v.display_slug = ")
                .push_bind(slug.clone())
                .push(")");
            qb.push(" AND (v.slug = ")
                .push_bind(slug.clone())
                .push(" OR v.display_slug = ")
                .push_bind(slug.clone())
                .push(")");
        }
        if let Some(neighborhood) = &filters.neighborhood {
            count_qb
                .push(" AND v.neighborhood = ")
                .push_bind(neighborhood.clone());
            qb.push(" AND v.neighborhood = ")
                .push_bind(neighborhood.clone());
        }
        if let Some(price_max) = &filters.price_max {
            count_qb.push(" AND e.min_price <= ").push_bind(*price_max);
            qb.push(" AND e.min_price <= ").push_bind(*price_max);
        }
        if let Some(status) = &filters.status {
            count_qb.push(" AND e.status = ").push_bind(*status);
            qb.push(" AND e.status = ").push_bind(*status);
        }
        if let Some(genre) = &filters.genre {
            count_qb.push(
                " AND EXISTS (SELECT 1 FROM event_artists ea JOIN artists a ON a.id = ea.artist_id WHERE ea.event_id = e.id AND ",
            ).push_bind(genre.clone()).push(" = ANY(a.genres))");
            qb.push(
                " AND EXISTS (SELECT 1 FROM event_artists ea JOIN artists a ON a.id = ea.artist_id WHERE ea.event_id = e.id AND ",
            ).push_bind(genre.clone()).push(" = ANY(a.genres))");
        }

        let total: i64 = count_qb.build_query_scalar().fetch_one(&*self.pool).await?;

        qb.push(" ORDER BY e.start_time ASC LIMIT ")
            .push_bind(page.per_page)
            .push(" OFFSET ")
            .push_bind(page.offset());

        let rows = qb
            .build_query_as::<EventRow>()
            .fetch_all(&*self.pool)
            .await?;

        Ok(Page {
            items: rows.into_iter().map(Event::from).collect(),
            total,
            page: page.page,
            per_page: page.per_page,
        })
    }

    async fn find_by_venue_id(&self, venue_id: VenueId) -> Result<Vec<Event>, RepoError> {
        let rows = sqlx::query_as::<_, EventRow>(
            r#"SELECT id, title, slug, description,
                      start_time, end_time, doors_time,
                      min_price, max_price, price_tier,
                      ticket_url, on_sale_date, sold_out, ticket_platform, image_url,
                      age_restriction, status, venue_id, title_parsed, event_type,
                      created_at, updated_at
               FROM events WHERE venue_id = $1 ORDER BY start_time"#,
        )
        .bind(venue_id.0)
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(Event::from).collect())
    }

    async fn find_related_events(
        &self,
        event_id: EventId,
        window_days: i64,
    ) -> Result<Vec<Event>, RepoError> {
        let rows = sqlx::query_as::<_, EventRow>(
            r#"SELECT e2.id, e2.title, e2.slug, e2.description,
                      e2.start_time, e2.end_time, e2.doors_time,
                      e2.min_price, e2.max_price, e2.price_tier,
                      e2.ticket_url, e2.on_sale_date, e2.sold_out, e2.ticket_platform, e2.image_url,
                      e2.age_restriction, e2.status, e2.venue_id, e2.title_parsed, e2.event_type,
                      e2.created_at, e2.updated_at
               FROM events e1
               JOIN events e2 ON e2.venue_id = e1.venue_id
               WHERE e1.id = $1
                 AND e2.id != $1
                 AND e2.status = 'ACTIVE'
                 AND e2.start_time BETWEEN e1.start_time - ($2 || ' days')::interval
                                       AND e1.start_time + ($2 || ' days')::interval
               ORDER BY e2.start_time"#,
        )
        .bind(event_id.0)
        .bind(window_days.to_string())
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(Event::from).collect())
    }

    async fn find_upcoming(&self) -> Result<Vec<Event>, RepoError> {
        let rows = sqlx::query_as::<_, EventRow>(
            r#"SELECT id, title, slug, description,
                      start_time, end_time, doors_time,
                      min_price, max_price, price_tier,
                      ticket_url, on_sale_date, sold_out, ticket_platform, image_url,
                      age_restriction, status, venue_id, title_parsed, event_type,
                      created_at, updated_at
               FROM events
               WHERE start_time > now() AND status = 'ACTIVE'
               ORDER BY start_time"#,
        )
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(Event::from).collect())
    }

    async fn count_upcoming_by_venue(&self) -> Result<Vec<(VenueId, i64)>, RepoError> {
        let rows = sqlx::query_as::<_, (Uuid, i64)>(
            r#"SELECT venue_id, COUNT(*) as count
               FROM events
               WHERE start_time > now()
                 AND venue_id IS NOT NULL
                 AND status = 'ACTIVE'
               GROUP BY venue_id"#,
        )
        .fetch_all(&*self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|(venue_id, count)| (VenueId(venue_id), count))
            .collect())
    }

    async fn find_sources_by_event_id(
        &self,
        event_id: EventId,
    ) -> Result<Vec<EventSource>, RepoError> {
        let rows = sqlx::query_as::<_, EventSourceRow>(
            r#"SELECT id, event_id, source_type, source_identifier, source_url,
                      last_scraped_at, confidence_score, created_at, source_id
               FROM event_sources
               WHERE event_id = $1
               ORDER BY created_at ASC"#,
        )
        .bind(event_id.0)
        .fetch_all(&*self.pool)
        .await?;

        Ok(rows.into_iter().map(EventSource::from).collect())
    }
}

// ---- Row types ----

#[derive(sqlx::FromRow)]
struct EventRow {
    id: Uuid,
    title: String,
    slug: String,
    description: Option<String>,
    start_time: OffsetDateTime,
    end_time: Option<OffsetDateTime>,
    doors_time: Option<OffsetDateTime>,
    min_price: Option<rust_decimal::Decimal>,
    max_price: Option<rust_decimal::Decimal>,
    price_tier: Option<PriceTier>,
    ticket_url: Option<String>,
    on_sale_date: Option<OffsetDateTime>,
    sold_out: bool,
    ticket_platform: Option<String>,
    image_url: Option<String>,
    age_restriction: AgeRestriction,
    status: EventStatus,
    venue_id: Option<Uuid>,
    title_parsed: bool,
    event_type: Option<EventType>,
    created_at: OffsetDateTime,
    updated_at: OffsetDateTime,
}

impl From<EventRow> for Event {
    fn from(r: EventRow) -> Self {
        Event {
            id: EventId(r.id),
            title: r.title,
            slug: r.slug,
            description: r.description,
            start_time: r.start_time,
            end_time: r.end_time,
            doors_time: r.doors_time,
            min_price: r.min_price,
            max_price: r.max_price,
            price_tier: r.price_tier,
            ticket_url: r.ticket_url,
            on_sale_date: r.on_sale_date,
            sold_out: r.sold_out,
            ticket_platform: r.ticket_platform,
            image_url: r.image_url,
            age_restriction: r.age_restriction,
            status: r.status,
            venue_id: r.venue_id.map(VenueId),
            title_parsed: r.title_parsed,
            event_type: r.event_type,
            created_at: r.created_at,
            updated_at: r.updated_at,
        }
    }
}

#[derive(sqlx::FromRow)]
struct EventSourceRow {
    id: Uuid,
    event_id: Uuid,
    source_type: SourceType,
    source_identifier: Option<String>,
    source_url: Option<String>,
    last_scraped_at: Option<OffsetDateTime>,
    confidence_score: rust_decimal::Decimal,
    created_at: OffsetDateTime,
    source_id: Option<Uuid>,
}

impl From<EventSourceRow> for EventSource {
    fn from(r: EventSourceRow) -> Self {
        EventSource {
            id: EventSourceId(r.id),
            event_id: EventId(r.event_id),
            source_type: r.source_type,
            source_identifier: r.source_identifier,
            source_url: r.source_url,
            last_scraped_at: r.last_scraped_at,
            confidence_score: r.confidence_score,
            created_at: r.created_at,
            source_id: r.source_id.map(SourceId),
        }
    }
}
