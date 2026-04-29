use async_trait::async_trait;

use crate::domain::{
    error::RepoError,
    featured_event::{FeaturedEvent, FeaturedEventId},
};

#[async_trait]
pub trait FeaturedEventRepository: Send + Sync {
    async fn find_current(&self) -> Result<Option<FeaturedEvent>, RepoError>;
    async fn find_all_desc(&self) -> Result<Vec<FeaturedEvent>, RepoError>;
    async fn find_by_id(&self, id: FeaturedEventId) -> Result<FeaturedEvent, RepoError>;
    async fn save(&self, featured: &FeaturedEvent) -> Result<FeaturedEvent, RepoError>;
}
