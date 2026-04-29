use async_trait::async_trait;

use crate::domain::{
    artist::{EnrichmentResult, EnrichmentSource},
    error::EnrichmentError,
};

#[async_trait]
pub trait ArtistEnricher: Send + Sync {
    /// Which enrichment service this adapter queries.
    fn source(&self) -> EnrichmentSource;

    /// Look up metadata for an artist by name.
    ///
    /// Returns `Ok(None)` if no match is found (not an error — just unknown artist).
    /// Returns `Err` only for transient failures (HTTP errors, rate limits).
    async fn enrich(
        &self,
        name: &str,
    ) -> Result<Option<EnrichmentResult>, EnrichmentError>;
}
