use async_trait::async_trait;

use crate::domain::{
    error::RepoError,
    ingestion_run::{IngestionRun, IngestionRunId},
    source::SourceId,
};

#[async_trait]
pub trait IngestionRunRepository: Send + Sync {
    async fn create(&self, source_id: SourceId) -> Result<IngestionRun, RepoError>;
    async fn mark_success(
        &self,
        id: IngestionRunId,
        events_fetched: i32,
        events_created: i32,
        events_updated: i32,
        events_deduplicated: i32,
    ) -> Result<(), RepoError>;
    async fn mark_failed(&self, id: IngestionRunId, error_message: &str) -> Result<(), RepoError>;
    async fn find_by_source_id_desc(&self, source_id: SourceId) -> Result<Vec<IngestionRun>, RepoError>;
}
