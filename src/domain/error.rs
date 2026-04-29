//! Domain error types shared across ports and adapters.

/// Errors returned by repository port implementations.
#[derive(Debug, thiserror::Error)]
pub enum RepoError {
    #[error("record not found")]
    NotFound,
    #[error("database error: {0}")]
    Database(#[from] sqlx::Error),
}

/// Errors returned by `SourceConnector::fetch` implementations.
#[derive(Debug, thiserror::Error)]
pub enum IngestionError {
    #[error("HTTP error fetching {url}: {source}")]
    Http {
        url: String,
        #[source]
        source: reqwest::Error,
    },
    #[error("parse error: {0}")]
    Parse(String),
    #[error("ingestion is disabled")]
    Disabled,
    #[error("database error: {0}")]
    Database(#[from] sqlx::Error),
    /// Wraps a repository error, enabling `?` from repo calls in the ingestion orchestrator.
    #[error("repository error: {0}")]
    Repo(#[from] RepoError),
}

/// Errors returned by `ArtistEnricher::enrich` implementations.
#[derive(Debug, thiserror::Error)]
pub enum EnrichmentError {
    #[error("HTTP error: {0}")]
    Http(#[from] reqwest::Error),
    #[error("rate limited by upstream API")]
    RateLimited,
    #[error("API error: {0}")]
    Api(String),
    #[error("enrichment is disabled")]
    Disabled,
}
