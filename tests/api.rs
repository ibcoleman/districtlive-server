use axum_test::TestServer;
use districtlive_server::config::Config;
use districtlive_server::http::{router, AppState};
use std::sync::Arc;

#[cfg(feature = "test-helpers")]
mod test_adapters {
    use async_trait::async_trait;
    use districtlive_server::domain::{
        artist::{Artist, ArtistId},
        error::RepoError,
        event::{Event, EventFilters, EventId, EventUpsertCommand},
        featured_event::{FeaturedEvent, FeaturedEventId},
        ingestion_run::{IngestionRun, IngestionRunId},
        source::{Source, SourceId},
        venue::{Venue, VenueId},
        Page, Pagination,
    };
    use districtlive_server::ports::{
        event_repository::UpsertResult, ArtistRepository, EventRepository, FeaturedEventRepository,
        IngestionRunRepository, SourceRepository, VenueRepository,
    };

    pub struct TestVenueRepository;
    pub struct TestArtistRepository;
    pub struct TestEventRepository;
    pub struct TestFeaturedEventRepository;
    pub struct TestSourceRepository;
    pub struct TestIngestionRunRepository;

    #[async_trait]
    impl VenueRepository for TestVenueRepository {
        async fn find_by_id(&self, _id: VenueId) -> Result<Venue, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_by_slug(&self, _slug: &str) -> Result<Option<Venue>, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_by_name(&self, _name: &str) -> Result<Option<Venue>, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_by_neighborhood(&self, _neighborhood: &str) -> Result<Vec<Venue>, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_all(&self, _page: Pagination) -> Result<Page<Venue>, RepoError> {
            unimplemented!("test stub")
        }
        async fn save(&self, _venue: &Venue) -> Result<Venue, RepoError> {
            unimplemented!("test stub")
        }
    }

    #[async_trait]
    impl ArtistRepository for TestArtistRepository {
        async fn find_by_id(&self, _id: ArtistId) -> Result<Artist, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_by_slug(&self, _slug: &str) -> Result<Option<Artist>, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_by_name(&self, _name: &str) -> Result<Option<Artist>, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_all(&self, _page: Pagination) -> Result<Page<Artist>, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_local(&self) -> Result<Vec<Artist>, RepoError> {
            unimplemented!("test stub")
        }
        async fn save(&self, _artist: &Artist) -> Result<Artist, RepoError> {
            unimplemented!("test stub")
        }
        async fn claim_pending_batch(&self, _batch_size: i64) -> Result<Vec<Artist>, RepoError> {
            unimplemented!("test stub")
        }
        async fn reset_in_progress_to_pending(&self) -> Result<u64, RepoError> {
            unimplemented!("test stub")
        }
        async fn reset_eligible_failed_to_pending(
            &self,
            _max_attempts: i32,
        ) -> Result<u64, RepoError> {
            unimplemented!("test stub")
        }
    }

    #[async_trait]
    impl EventRepository for TestEventRepository {
        async fn upsert(&self, _cmd: EventUpsertCommand) -> Result<UpsertResult, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_by_id(&self, _id: EventId) -> Result<Event, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_by_slug(&self, _slug: &str) -> Result<Option<Event>, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_all(
            &self,
            _filters: EventFilters,
            _page: Pagination,
        ) -> Result<Page<Event>, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_by_venue_id(&self, _venue_id: VenueId) -> Result<Vec<Event>, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_related_events(
            &self,
            _event_id: EventId,
            _window_days: i64,
        ) -> Result<Vec<Event>, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_upcoming(&self) -> Result<Vec<Event>, RepoError> {
            unimplemented!("test stub")
        }
        async fn count_upcoming_by_venue(&self) -> Result<Vec<(VenueId, i64)>, RepoError> {
            unimplemented!("test stub")
        }
    }

    #[async_trait]
    impl FeaturedEventRepository for TestFeaturedEventRepository {
        async fn find_current(&self) -> Result<Option<FeaturedEvent>, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_all_desc(&self) -> Result<Vec<FeaturedEvent>, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_by_id(&self, _id: FeaturedEventId) -> Result<FeaturedEvent, RepoError> {
            unimplemented!("test stub")
        }
        async fn save(&self, _featured: &FeaturedEvent) -> Result<FeaturedEvent, RepoError> {
            unimplemented!("test stub")
        }
    }

    #[async_trait]
    impl SourceRepository for TestSourceRepository {
        async fn find_by_id(&self, _id: SourceId) -> Result<Source, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_by_name(&self, _name: &str) -> Result<Option<Source>, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_all(&self) -> Result<Vec<Source>, RepoError> {
            unimplemented!("test stub")
        }
        async fn find_healthy(&self) -> Result<Vec<Source>, RepoError> {
            unimplemented!("test stub")
        }
        async fn record_success(&self, _id: SourceId) -> Result<(), RepoError> {
            unimplemented!("test stub")
        }
        async fn record_failure(&self, _id: SourceId, _error_msg: &str) -> Result<(), RepoError> {
            unimplemented!("test stub")
        }
    }

    #[async_trait]
    impl IngestionRunRepository for TestIngestionRunRepository {
        async fn create(&self, _source_id: SourceId) -> Result<IngestionRun, RepoError> {
            unimplemented!("test stub")
        }
        async fn mark_success(
            &self,
            _id: IngestionRunId,
            _events_fetched: i32,
            _events_created: i32,
            _events_updated: i32,
            _events_deduplicated: i32,
        ) -> Result<(), RepoError> {
            unimplemented!("test stub")
        }
        async fn mark_failed(
            &self,
            _id: IngestionRunId,
            _error_message: &str,
        ) -> Result<(), RepoError> {
            unimplemented!("test stub")
        }
        async fn find_by_source_id_desc(
            &self,
            _source_id: SourceId,
        ) -> Result<Vec<IngestionRun>, RepoError> {
            unimplemented!("test stub")
        }
    }
}

#[tokio::test]
async fn healthz_returns_ok() {
    // Arrange
    #[cfg(feature = "test-helpers")]
    {
        use test_adapters::*;
        let state = AppState {
            config: Arc::new(Config::test_default()),
            venues: Arc::new(TestVenueRepository),
            artists: Arc::new(TestArtistRepository),
            events: Arc::new(TestEventRepository),
            featured: Arc::new(TestFeaturedEventRepository),
            sources: Arc::new(TestSourceRepository),
            ingestion_runs: Arc::new(TestIngestionRunRepository),
        };
        let app = router(state);
        let server = TestServer::new(app).expect("failed to create test server");

        // Act
        let resp = server.get("/healthz").await;

        // Assert
        resp.assert_status_ok();
        resp.assert_text("ok");
    }

    #[cfg(not(feature = "test-helpers"))]
    {
        panic!("This test requires the test-helpers feature");
    }
}
