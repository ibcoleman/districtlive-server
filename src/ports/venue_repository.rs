use async_trait::async_trait;

use crate::domain::{
    error::RepoError,
    venue::{Venue, VenueId},
    Page, Pagination,
};

#[async_trait]
pub trait VenueRepository: Send + Sync {
    async fn find_by_id(&self, id: VenueId) -> Result<Venue, RepoError>;
    async fn find_by_slug(&self, slug: &str) -> Result<Venue, RepoError>;
    async fn find_by_name(&self, name: &str) -> Result<Option<Venue>, RepoError>;
    async fn find_by_neighborhood(&self, neighborhood: &str) -> Result<Vec<Venue>, RepoError>;
    async fn find_all(&self, page: Pagination) -> Result<Page<Venue>, RepoError>;
    async fn save(&self, venue: &Venue) -> Result<Venue, RepoError>;
}
