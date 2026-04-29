use async_trait::async_trait;

use crate::domain::{error::IngestionError, event::RawEvent, source::SourceType};

#[async_trait]
pub trait SourceConnector: Send + Sync {
    /// Stable identifier for this connector matching the `sources.name` DB column.
    fn source_id(&self) -> &str;

    fn source_type(&self) -> SourceType;

    /// Fetch current events from the external source.
    async fn fetch(&self) -> Result<Vec<RawEvent>, IngestionError>;

    /// Returns `false` if the connector has a known configuration problem.
    fn health_check(&self) -> bool {
        true
    }
}
