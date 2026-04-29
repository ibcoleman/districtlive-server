//! Port traits — the interfaces between domain logic and infrastructure.
//!
//! Each trait is implemented by an adapter in `src/adapters/`.
//! All traits are object-safe (used as `Arc<dyn Trait>` in `AppState`),
//! which requires `#[async_trait]` for async methods.

pub mod artist_enricher;
pub mod artist_repository;
pub mod event_repository;
pub mod featured_event_repository;
pub mod ingestion_run_repository;
pub mod source_connector;
pub mod source_repository;
pub mod venue_repository;

pub use artist_enricher::ArtistEnricher;
pub use artist_repository::ArtistRepository;
pub use event_repository::EventRepository;
pub use featured_event_repository::FeaturedEventRepository;
pub use ingestion_run_repository::IngestionRunRepository;
pub use source_connector::SourceConnector;
pub use source_repository::SourceRepository;
pub use venue_repository::VenueRepository;
