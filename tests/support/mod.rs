//! Test support — fake adapters for unit testing HTTP handlers.

#![cfg(feature = "test-helpers")]

use async_trait::async_trait;
use districtlive_server::{
    domain::{
        artist::{Artist, ArtistId},
        error::RepoError,
        event::{Event, EventFilters, EventId, EventUpsertCommand},
        featured_event::{FeaturedEvent, FeaturedEventId},
        ingestion_run::{IngestionRun, IngestionRunId},
        source::{Source, SourceId},
        venue::{Venue, VenueId},
        Page, Pagination,
    },
    ports::{
        event_repository::UpsertResult, ArtistRepository, EventRepository, FeaturedEventRepository,
        IngestionRunRepository, SourceRepository, VenueRepository,
    },
};

/// Always-empty source repository for testing.
pub struct EmptySourceRepository;

#[async_trait]
impl SourceRepository for EmptySourceRepository {
    async fn find_by_id(&self, _id: SourceId) -> Result<Source, RepoError> {
        Err(RepoError::NotFound)
    }
    async fn find_by_name(&self, _name: &str) -> Result<Option<Source>, RepoError> {
        Ok(None)
    }
    async fn find_all(&self) -> Result<Vec<Source>, RepoError> {
        Ok(vec![])
    }
    async fn find_healthy(&self) -> Result<Vec<Source>, RepoError> {
        Ok(vec![])
    }
    async fn record_success(&self, _id: SourceId) -> Result<(), RepoError> {
        Ok(())
    }
    async fn record_failure(&self, _id: SourceId, _msg: &str) -> Result<(), RepoError> {
        Ok(())
    }
}

/// Always-empty event repository for testing.
pub struct EmptyEventRepository;

#[async_trait]
impl EventRepository for EmptyEventRepository {
    async fn upsert(&self, _cmd: EventUpsertCommand) -> Result<UpsertResult, RepoError> {
        Ok(UpsertResult::Created)
    }
    async fn find_by_id(&self, _id: EventId) -> Result<Event, RepoError> {
        Err(RepoError::NotFound)
    }
    async fn find_by_slug(&self, _slug: &str) -> Result<Option<Event>, RepoError> {
        Ok(None)
    }
    async fn find_all(&self, _f: EventFilters, _p: Pagination) -> Result<Page<Event>, RepoError> {
        Ok(Page {
            items: vec![],
            total: 0,
            page: 0,
            per_page: 20,
        })
    }
    async fn find_by_venue_id(&self, _id: VenueId) -> Result<Vec<Event>, RepoError> {
        Ok(vec![])
    }
    async fn find_related_events(&self, _id: EventId, _days: i64) -> Result<Vec<Event>, RepoError> {
        Ok(vec![])
    }
    async fn find_upcoming(&self) -> Result<Vec<Event>, RepoError> {
        Ok(vec![])
    }
    async fn count_upcoming_by_venue(&self) -> Result<Vec<(VenueId, i64)>, RepoError> {
        Ok(vec![])
    }
}

/// Always-empty venue repository for testing.
pub struct EmptyVenueRepository;

#[async_trait]
impl VenueRepository for EmptyVenueRepository {
    async fn find_by_id(&self, _id: VenueId) -> Result<Venue, RepoError> {
        Err(RepoError::NotFound)
    }
    async fn find_by_slug(&self, _slug: &str) -> Result<Option<Venue>, RepoError> {
        Ok(None)
    }
    async fn find_by_name(&self, _name: &str) -> Result<Option<Venue>, RepoError> {
        Ok(None)
    }
    async fn find_by_neighborhood(&self, _neighborhood: &str) -> Result<Vec<Venue>, RepoError> {
        Ok(vec![])
    }
    async fn find_all(&self, _page: Pagination) -> Result<Page<Venue>, RepoError> {
        Ok(Page {
            items: vec![],
            total: 0,
            page: 0,
            per_page: 20,
        })
    }
    async fn save(&self, _venue: &Venue) -> Result<Venue, RepoError> {
        Err(RepoError::NotFound)
    }
}

/// Always-empty artist repository for testing.
pub struct EmptyArtistRepository;

#[async_trait]
impl ArtistRepository for EmptyArtistRepository {
    async fn find_by_id(&self, _id: ArtistId) -> Result<Artist, RepoError> {
        Err(RepoError::NotFound)
    }
    async fn find_by_slug(&self, _slug: &str) -> Result<Option<Artist>, RepoError> {
        Ok(None)
    }
    async fn find_by_name(&self, _name: &str) -> Result<Option<Artist>, RepoError> {
        Ok(None)
    }
    async fn find_all(&self, _page: Pagination) -> Result<Page<Artist>, RepoError> {
        Ok(Page {
            items: vec![],
            total: 0,
            page: 0,
            per_page: 20,
        })
    }
    async fn find_local(&self) -> Result<Vec<Artist>, RepoError> {
        Ok(vec![])
    }
    async fn save(&self, _artist: &Artist) -> Result<Artist, RepoError> {
        Err(RepoError::NotFound)
    }
    async fn claim_pending_batch(&self, _batch_size: i64) -> Result<Vec<Artist>, RepoError> {
        Ok(vec![])
    }
    async fn reset_in_progress_to_pending(&self) -> Result<u64, RepoError> {
        Ok(0)
    }
    async fn reset_eligible_failed_to_pending(&self, _max_attempts: i32) -> Result<u64, RepoError> {
        Ok(0)
    }
    async fn find_by_event_id(&self, _event_id: EventId) -> Result<Vec<Artist>, RepoError> {
        Ok(vec![])
    }
}

/// Always-empty featured event repository for testing.
pub struct EmptyFeaturedRepository;

#[async_trait]
impl FeaturedEventRepository for EmptyFeaturedRepository {
    async fn find_current(&self) -> Result<Option<FeaturedEvent>, RepoError> {
        Ok(None)
    }
    async fn find_all_desc(&self) -> Result<Vec<FeaturedEvent>, RepoError> {
        Ok(vec![])
    }
    async fn find_by_id(&self, _id: FeaturedEventId) -> Result<FeaturedEvent, RepoError> {
        Err(RepoError::NotFound)
    }
    async fn save(&self, _featured: &FeaturedEvent) -> Result<FeaturedEvent, RepoError> {
        Err(RepoError::NotFound)
    }
}

/// Always-empty ingestion run repository for testing.
pub struct EmptyIngestionRunRepository;

#[async_trait]
impl IngestionRunRepository for EmptyIngestionRunRepository {
    async fn create(&self, _source_id: SourceId) -> Result<IngestionRun, RepoError> {
        Err(RepoError::NotFound)
    }
    async fn mark_success(
        &self,
        _id: IngestionRunId,
        _events_fetched: i32,
        _events_created: i32,
        _events_updated: i32,
        _events_deduplicated: i32,
    ) -> Result<(), RepoError> {
        Ok(())
    }
    async fn mark_failed(
        &self,
        _id: IngestionRunId,
        _error_message: &str,
    ) -> Result<(), RepoError> {
        Ok(())
    }
    async fn find_by_source_id_desc(
        &self,
        _source_id: SourceId,
    ) -> Result<Vec<IngestionRun>, RepoError> {
        Ok(vec![])
    }
}

/// Construct a test AppState with empty repositories and test credentials.
pub fn test_state() -> districtlive_server::http::AppState {
    use districtlive_server::{config::Config, http::AppState};
    use std::sync::Arc;

    let config = Arc::new(Config::test_default());
    AppState {
        config,
        venues: Arc::new(EmptyVenueRepository),
        artists: Arc::new(EmptyArtistRepository),
        events: Arc::new(EmptyEventRepository),
        featured: Arc::new(EmptyFeaturedRepository),
        sources: Arc::new(EmptySourceRepository),
        ingestion_runs: Arc::new(EmptyIngestionRunRepository),
        http_client: reqwest::Client::new(),
        ingestion_orchestrator: None,
        connectors: vec![],
    }
}
