use async_trait::async_trait;

use crate::domain::{
    artist::{Artist, ArtistId},
    error::RepoError,
    event::EventId,
    Page, Pagination,
};

#[async_trait]
pub trait ArtistRepository: Send + Sync {
    async fn find_by_id(&self, id: ArtistId) -> Result<Artist, RepoError>;
    async fn find_by_slug(&self, slug: &str) -> Result<Option<Artist>, RepoError>;
    async fn find_by_name(&self, name: &str) -> Result<Option<Artist>, RepoError>;
    async fn find_all(&self, page: Pagination) -> Result<Page<Artist>, RepoError>;
    async fn find_local(&self) -> Result<Vec<Artist>, RepoError>;
    async fn save(&self, artist: &Artist) -> Result<Artist, RepoError>;

    /// Atomically claim a batch of PENDING artists and mark them IN_PROGRESS.
    ///
    /// Uses `SELECT ... FOR UPDATE SKIP LOCKED` to safely distribute work
    /// across concurrent enrichment workers.
    async fn claim_pending_batch(&self, batch_size: i64) -> Result<Vec<Artist>, RepoError>;

    /// Reset any IN_PROGRESS artists to PENDING (called at startup to recover from crashes).
    async fn reset_in_progress_to_pending(&self) -> Result<u64, RepoError>;

    /// Reset FAILED artists that have not exceeded `max_attempts` back to PENDING.
    async fn reset_eligible_failed_to_pending(&self, max_attempts: i32) -> Result<u64, RepoError>;

    /// Find all artists for a given event.
    async fn find_by_event_id(&self, event_id: EventId) -> Result<Vec<Artist>, RepoError>;
}
