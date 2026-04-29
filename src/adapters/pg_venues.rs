use async_trait::async_trait;
use sqlx::PgPool;
use std::sync::Arc;
use time::OffsetDateTime;

use crate::domain::{
    error::RepoError,
    venue::{Venue, VenueId},
    Page, Pagination,
};
use crate::ports::VenueRepository;

#[derive(Clone)]
pub struct PgVenueRepository {
    pool: Arc<PgPool>,
}

impl PgVenueRepository {
    pub fn new(pool: Arc<PgPool>) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl VenueRepository for PgVenueRepository {
    async fn find_by_id(&self, id: VenueId) -> Result<Venue, RepoError> {
        sqlx::query_as::<_, VenueRow>(
            r#"SELECT id, name, slug, address, neighborhood,
                      capacity, venue_type, website_url, display_name, display_slug,
                      created_at, updated_at
               FROM venues WHERE id = $1"#,
        )
        .bind(id.0)
        .fetch_optional(&*self.pool)
        .await?
        .map(Venue::from)
        .ok_or(RepoError::NotFound)
    }

    async fn find_by_slug(&self, slug: &str) -> Result<Option<Venue>, RepoError> {
        let row = sqlx::query_as::<_, VenueRow>(
            r#"SELECT id, name, slug, address, neighborhood,
                      capacity, venue_type, website_url, display_name, display_slug,
                      created_at, updated_at
               FROM venues WHERE slug = $1 OR display_slug = $1"#,
        )
        .bind(slug)
        .fetch_optional(&*self.pool)
        .await?;
        Ok(row.map(Venue::from))
    }

    async fn find_by_name(&self, name: &str) -> Result<Option<Venue>, RepoError> {
        let row = sqlx::query_as::<_, VenueRow>(
            r#"SELECT id, name, slug, address, neighborhood,
                      capacity, venue_type, website_url, display_name, display_slug,
                      created_at, updated_at
               FROM venues WHERE lower(name) = lower($1)"#,
        )
        .bind(name)
        .fetch_optional(&*self.pool)
        .await?;
        Ok(row.map(Venue::from))
    }

    async fn find_by_neighborhood(&self, neighborhood: &str) -> Result<Vec<Venue>, RepoError> {
        let rows = sqlx::query_as::<_, VenueRow>(
            r#"SELECT id, name, slug, address, neighborhood,
                      capacity, venue_type, website_url, display_name, display_slug,
                      created_at, updated_at
               FROM venues WHERE neighborhood = $1 ORDER BY name"#,
        )
        .bind(neighborhood)
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(Venue::from).collect())
    }

    async fn find_all(&self, page: Pagination) -> Result<Page<Venue>, RepoError> {
        let total: i64 = sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM venues")
            .fetch_one(&*self.pool)
            .await?;

        let rows = sqlx::query_as::<_, VenueRow>(
            r#"SELECT id, name, slug, address, neighborhood,
                      capacity, venue_type, website_url, display_name, display_slug,
                      created_at, updated_at
               FROM venues ORDER BY name
               LIMIT $1 OFFSET $2"#,
        )
        .bind(page.per_page)
        .bind(page.offset())
        .fetch_all(&*self.pool)
        .await?;

        Ok(Page {
            items: rows.into_iter().map(Venue::from).collect(),
            total,
            page: page.page,
            per_page: page.per_page,
        })
    }

    async fn save(&self, venue: &Venue) -> Result<Venue, RepoError> {
        sqlx::query(
            r#"INSERT INTO venues (id, name, slug, address, neighborhood, capacity,
                                   venue_type, website_url, display_name, display_slug,
                                   created_at, updated_at)
               VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
               ON CONFLICT (id) DO UPDATE SET
                   name = EXCLUDED.name, slug = EXCLUDED.slug,
                   address = EXCLUDED.address, neighborhood = EXCLUDED.neighborhood,
                   display_name = EXCLUDED.display_name, display_slug = EXCLUDED.display_slug,
                   updated_at = now()"#,
        )
        .bind(venue.id.0)
        .bind(&venue.name)
        .bind(&venue.slug)
        .bind(venue.address.as_deref())
        .bind(venue.neighborhood.as_deref())
        .bind(venue.capacity)
        .bind(venue.venue_type.as_deref())
        .bind(venue.website_url.as_deref())
        .bind(venue.display_name.as_deref())
        .bind(venue.display_slug.as_deref())
        .bind(venue.created_at)
        .bind(venue.updated_at)
        .execute(&*self.pool)
        .await?;
        self.find_by_id(venue.id).await
    }
}

// ---- Row type for sqlx deserialization ----

#[derive(sqlx::FromRow)]
struct VenueRow {
    id: uuid::Uuid,
    name: String,
    slug: String,
    address: Option<String>,
    neighborhood: Option<String>,
    capacity: Option<i32>,
    venue_type: Option<String>,
    website_url: Option<String>,
    display_name: Option<String>,
    display_slug: Option<String>,
    created_at: OffsetDateTime,
    updated_at: OffsetDateTime,
}

impl From<VenueRow> for Venue {
    fn from(r: VenueRow) -> Self {
        Venue {
            id: VenueId(r.id),
            name: r.name,
            slug: r.slug,
            address: r.address,
            neighborhood: r.neighborhood,
            capacity: r.capacity,
            venue_type: r.venue_type,
            website_url: r.website_url,
            display_name: r.display_name,
            display_slug: r.display_slug,
            created_at: r.created_at,
            updated_at: r.updated_at,
        }
    }
}
