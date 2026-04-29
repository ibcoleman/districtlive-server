use async_trait::async_trait;
use sqlx::PgPool;
use std::sync::Arc;
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::{
    artist::{Artist, ArtistId, EnrichmentStatus},
    error::RepoError,
    Page, Pagination,
};
use crate::ports::ArtistRepository;

#[derive(Clone)]
pub struct PgArtistRepository {
    pool: Arc<PgPool>,
}

impl PgArtistRepository {
    pub fn new(pool: Arc<PgPool>) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl ArtistRepository for PgArtistRepository {
    async fn find_by_id(&self, id: ArtistId) -> Result<Artist, RepoError> {
        sqlx::query_as::<_, ArtistRow>(
            r#"SELECT id, name, slug, genres, is_local,
                      spotify_url, bandcamp_url, instagram_url,
                      enrichment_status, enrichment_attempts, last_enriched_at, musicbrainz_id,
                      spotify_id, canonical_name, mb_tags, spotify_genres,
                      image_url, created_at, updated_at
               FROM artists WHERE id = $1"#,
        )
        .bind(id.0)
        .fetch_optional(&*self.pool)
        .await?
        .map(Artist::from)
        .ok_or(RepoError::NotFound)
    }

    async fn find_by_slug(&self, slug: &str) -> Result<Option<Artist>, RepoError> {
        let row = sqlx::query_as::<_, ArtistRow>(
            r#"SELECT id, name, slug, genres, is_local,
                      spotify_url, bandcamp_url, instagram_url,
                      enrichment_status, enrichment_attempts, last_enriched_at, musicbrainz_id,
                      spotify_id, canonical_name, mb_tags, spotify_genres,
                      image_url, created_at, updated_at
               FROM artists WHERE slug = $1"#,
        )
        .bind(slug)
        .fetch_optional(&*self.pool)
        .await?;
        Ok(row.map(Artist::from))
    }

    async fn find_by_name(&self, name: &str) -> Result<Option<Artist>, RepoError> {
        let row = sqlx::query_as::<_, ArtistRow>(
            r#"SELECT id, name, slug, genres, is_local,
                      spotify_url, bandcamp_url, instagram_url,
                      enrichment_status, enrichment_attempts, last_enriched_at, musicbrainz_id,
                      spotify_id, canonical_name, mb_tags, spotify_genres,
                      image_url, created_at, updated_at
               FROM artists WHERE lower(name) = lower($1)"#,
        )
        .bind(name)
        .fetch_optional(&*self.pool)
        .await?;
        Ok(row.map(Artist::from))
    }

    async fn find_all(&self, page: Pagination) -> Result<Page<Artist>, RepoError> {
        let total: i64 = sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM artists")
            .fetch_one(&*self.pool)
            .await?;

        let rows = sqlx::query_as::<_, ArtistRow>(
            r#"SELECT id, name, slug, genres, is_local,
                      spotify_url, bandcamp_url, instagram_url,
                      enrichment_status, enrichment_attempts, last_enriched_at, musicbrainz_id,
                      spotify_id, canonical_name, mb_tags, spotify_genres,
                      image_url, created_at, updated_at
               FROM artists ORDER BY name
               LIMIT $1 OFFSET $2"#,
        )
        .bind(page.per_page)
        .bind(page.offset())
        .fetch_all(&*self.pool)
        .await?;

        Ok(Page {
            items: rows.into_iter().map(Artist::from).collect(),
            total,
            page: page.page,
            per_page: page.per_page,
        })
    }

    async fn find_local(&self) -> Result<Vec<Artist>, RepoError> {
        let rows = sqlx::query_as::<_, ArtistRow>(
            r#"SELECT id, name, slug, genres, is_local,
                      spotify_url, bandcamp_url, instagram_url,
                      enrichment_status, enrichment_attempts, last_enriched_at, musicbrainz_id,
                      spotify_id, canonical_name, mb_tags, spotify_genres,
                      image_url, created_at, updated_at
               FROM artists WHERE is_local = true ORDER BY name"#,
        )
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(Artist::from).collect())
    }

    async fn save(&self, artist: &Artist) -> Result<Artist, RepoError> {
        sqlx::query(
            r#"INSERT INTO artists (id, name, slug, genres, is_local,
                                    enrichment_status, enrichment_attempts,
                                    created_at, updated_at)
               VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
               ON CONFLICT (id) DO UPDATE SET
                   name = EXCLUDED.name,
                   enrichment_status = EXCLUDED.enrichment_status,
                   enrichment_attempts = EXCLUDED.enrichment_attempts,
                   canonical_name = EXCLUDED.canonical_name,
                   musicbrainz_id = EXCLUDED.musicbrainz_id,
                   spotify_id = EXCLUDED.spotify_id,
                   mb_tags = EXCLUDED.mb_tags,
                   spotify_genres = EXCLUDED.spotify_genres,
                   image_url = EXCLUDED.image_url,
                   last_enriched_at = EXCLUDED.last_enriched_at,
                   updated_at = now()"#,
        )
        .bind(artist.id.0)
        .bind(&artist.name)
        .bind(&artist.slug)
        .bind(&artist.genres as &[String])
        .bind(artist.is_local)
        .bind(artist.enrichment_status as EnrichmentStatus)
        .bind(artist.enrichment_attempts)
        .bind(artist.created_at)
        .bind(artist.updated_at)
        .execute(&*self.pool)
        .await?;
        self.find_by_id(artist.id).await
    }

    async fn claim_pending_batch(&self, batch_size: i64) -> Result<Vec<Artist>, RepoError> {
        let mut tx = self.pool.begin().await?;

        // Step 1: Lock a batch of PENDING artists, skipping any locked by other workers.
        let ids: Vec<Uuid> = sqlx::query_scalar::<_, Uuid>(
            r#"SELECT id
               FROM artists
               WHERE enrichment_status = 'PENDING'
               ORDER BY created_at ASC
               LIMIT $1
               FOR UPDATE SKIP LOCKED"#,
        )
        .bind(batch_size)
        .fetch_all(&mut *tx)
        .await?;

        if ids.is_empty() {
            tx.rollback().await?;
            return Ok(vec![]);
        }

        // Step 2: Mark claimed artists as IN_PROGRESS atomically within the same transaction.
        sqlx::query(
            "UPDATE artists SET enrichment_status = 'IN_PROGRESS', updated_at = now() WHERE id = ANY($1)",
        )
        .bind(&ids as &[Uuid])
        .execute(&mut *tx)
        .await?;

        // Step 3: Fetch full artist records before committing.
        let rows = sqlx::query_as::<_, ArtistRow>(
            r#"SELECT id, name, slug, genres, is_local,
                      spotify_url, bandcamp_url, instagram_url,
                      enrichment_status, enrichment_attempts, last_enriched_at, musicbrainz_id,
                      spotify_id, canonical_name, mb_tags, spotify_genres,
                      image_url, created_at, updated_at
               FROM artists WHERE id = ANY($1)"#,
        )
        .bind(&ids as &[Uuid])
        .fetch_all(&mut *tx)
        .await?;

        tx.commit().await?;
        Ok(rows.into_iter().map(Artist::from).collect())
    }

    async fn reset_in_progress_to_pending(&self) -> Result<u64, RepoError> {
        let result = sqlx::query(
            "UPDATE artists SET enrichment_status = 'PENDING', updated_at = now() WHERE enrichment_status = 'IN_PROGRESS'",
        )
        .execute(&*self.pool)
        .await?;
        Ok(result.rows_affected())
    }

    async fn reset_eligible_failed_to_pending(&self, max_attempts: i32) -> Result<u64, RepoError> {
        let result = sqlx::query(
            "UPDATE artists SET enrichment_status = 'PENDING', updated_at = now() WHERE enrichment_status = 'FAILED' AND enrichment_attempts < $1",
        )
        .bind(max_attempts)
        .execute(&*self.pool)
        .await?;
        Ok(result.rows_affected())
    }

    async fn find_by_event_id(
        &self,
        event_id: crate::domain::event::EventId,
    ) -> Result<Vec<Artist>, RepoError> {
        let rows = sqlx::query_as::<_, ArtistRow>(
            r#"SELECT a.id, a.name, a.slug, a.genres, a.is_local,
                      a.spotify_url, a.bandcamp_url, a.instagram_url,
                      a.enrichment_status, a.enrichment_attempts, a.last_enriched_at, a.musicbrainz_id,
                      a.spotify_id, a.canonical_name, a.mb_tags, a.spotify_genres,
                      a.image_url, a.created_at, a.updated_at
               FROM artists a
               JOIN event_artists ea ON ea.artist_id = a.id
               WHERE ea.event_id = $1
               ORDER BY a.name"#,
        )
        .bind(event_id.0)
        .fetch_all(&*self.pool)
        .await?;
        Ok(rows.into_iter().map(Artist::from).collect())
    }
}

// ---- Row type ----

#[derive(sqlx::FromRow)]
struct ArtistRow {
    id: Uuid,
    name: String,
    slug: String,
    genres: Vec<String>,
    is_local: bool,
    spotify_url: Option<String>,
    bandcamp_url: Option<String>,
    instagram_url: Option<String>,
    enrichment_status: EnrichmentStatus,
    enrichment_attempts: i32,
    last_enriched_at: Option<OffsetDateTime>,
    musicbrainz_id: Option<String>,
    spotify_id: Option<String>,
    canonical_name: Option<String>,
    mb_tags: Vec<String>,
    spotify_genres: Vec<String>,
    image_url: Option<String>,
    created_at: OffsetDateTime,
    updated_at: OffsetDateTime,
}

impl From<ArtistRow> for Artist {
    fn from(r: ArtistRow) -> Self {
        Artist {
            id: ArtistId(r.id),
            name: r.name,
            slug: r.slug,
            genres: r.genres,
            is_local: r.is_local,
            spotify_url: r.spotify_url,
            bandcamp_url: r.bandcamp_url,
            instagram_url: r.instagram_url,
            enrichment_status: r.enrichment_status,
            enrichment_attempts: r.enrichment_attempts,
            last_enriched_at: r.last_enriched_at,
            musicbrainz_id: r.musicbrainz_id,
            spotify_id: r.spotify_id,
            canonical_name: r.canonical_name,
            mb_tags: r.mb_tags,
            spotify_genres: r.spotify_genres,
            image_url: r.image_url,
            created_at: r.created_at,
            updated_at: r.updated_at,
        }
    }
}
