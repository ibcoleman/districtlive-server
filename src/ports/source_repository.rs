use async_trait::async_trait;

use crate::domain::{
    error::RepoError,
    source::{Source, SourceId},
};

#[async_trait]
pub trait SourceRepository: Send + Sync {
    async fn find_by_id(&self, id: SourceId) -> Result<Source, RepoError>;
    async fn find_by_name(&self, name: &str) -> Result<Option<Source>, RepoError>;
    async fn find_all(&self) -> Result<Vec<Source>, RepoError>;
    async fn find_healthy(&self) -> Result<Vec<Source>, RepoError>;
    async fn record_success(&self, id: SourceId) -> Result<(), RepoError>;
    async fn record_failure(&self, id: SourceId, error_msg: &str) -> Result<(), RepoError>;
}
