//! Integration tests against a real PostgreSQL database.
//!
//! Requires `just dev` running on the host to provide PostgreSQL.
//! Run with: `just test-integration`
//!
//! Each test uses `helper.reset()` to start with a clean database.

#![cfg(feature = "test-helpers")]

use std::sync::Arc;

use districtlive_server::adapters::{connect, PgArtistRepository, PgEventRepository, TestHelper};
use districtlive_server::domain::{
    artist::{EnrichmentResult, EnrichmentSource, EnrichmentStatus},
    error::EnrichmentError,
    event::{AgeRestriction, EventUpsertCommand},
    event_source::SourceAttribution,
    source::SourceType,
    Pagination,
};
use districtlive_server::enrichment::orchestrator::EnrichmentOrchestrator;
use districtlive_server::ports::{ArtistEnricher, ArtistRepository, EventRepository};
use rust_decimal::Decimal;

async fn setup() -> (Arc<sqlx::PgPool>, TestHelper) {
    let url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://app:app@localhost:5432/app".to_owned());
    let pool = Arc::new(connect(&url).await.expect("Failed to connect to test DB"));
    let helper = TestHelper::new(pool.clone());
    helper.reset().await;
    (pool, helper)
}

// ---- Migration tests ----

#[tokio::test]
#[ignore]
async fn ac1_1_migrations_apply_cleanly() {
    // If setup() succeeds, migrations ran without error.
    let (_pool, _helper) = setup().await;
    // Nothing else to assert — connect() already ran migrations
}

#[tokio::test]
#[ignore]
async fn ac1_2_expected_tables_exist() {
    let (pool, _helper) = setup().await;
    for table in &[
        "venues",
        "artists",
        "events",
        "event_artists",
        "event_sources",
        "sources",
        "ingestion_runs",
        "featured_events",
    ] {
        let count: i64 = sqlx::query_scalar::<_, i64>(&format!(
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = '{}'",
            table
        ))
        .fetch_one(&*pool)
        .await
        .expect("Table check failed");
        assert!(count > 0, "Table {} should exist", table);
    }
}

#[tokio::test]
#[ignore]
async fn ac1_3_seed_data_present() {
    let (pool, _helper) = setup().await;
    // Seeds should be present — reset() only truncates non-seed tables
    // Note: if seed data is NOT idempotent across truncate, adjust this test
    let venue_count: i64 = sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM venues")
        .fetch_one(&*pool)
        .await
        .expect("Count failed");
    // The seed data from V8 populates DC venues — expect at least 5
    // (exact count depends on all seed migrations V8-V20)
    assert!(
        venue_count >= 5,
        "Expected seed venues, got {}",
        venue_count
    );
}

// ---- Event upsert tests ----

#[tokio::test]
#[ignore]
async fn event_upsert_creates_new_event() {
    let (pool, _helper) = setup().await;
    let events = PgEventRepository::new(pool.clone());

    let cmd = test_event_cmd("test-event-create-001");
    let result = events.upsert(cmd).await.expect("Upsert failed");

    use districtlive_server::ports::event_repository::UpsertResult;
    assert_eq!(result, UpsertResult::Created);
}

#[tokio::test]
#[ignore]
async fn ac1_4_event_upsert_updates_on_slug_conflict() {
    let (pool, _helper) = setup().await;
    let events = PgEventRepository::new(pool.clone());

    let cmd = test_event_cmd("test-event-dedup-001");
    let first = events
        .upsert(cmd.clone())
        .await
        .expect("First upsert failed");
    let second = events.upsert(cmd).await.expect("Second upsert failed");

    use districtlive_server::ports::event_repository::UpsertResult;
    assert_eq!(first, UpsertResult::Created);
    assert_eq!(second, UpsertResult::Updated);
}

// ---- Artist claim_pending_batch tests ----

#[tokio::test]
#[ignore]
async fn artist_claim_pending_batch_marks_in_progress() {
    let (pool, _helper) = setup().await;
    let events = PgEventRepository::new(pool.clone());
    let artists = PgArtistRepository::new(pool.clone());

    // Create an artist by upserting an event with that artist name
    let cmd = test_event_cmd("test-event-for-artist");
    events.upsert(cmd).await.expect("Setup upsert failed");

    // Claim it
    let claimed = artists.claim_pending_batch(10).await.expect("Claim failed");
    assert!(!claimed.is_empty(), "Expected at least one artist to claim");
    assert!(
        claimed
            .iter()
            .all(|a| a.enrichment_status == EnrichmentStatus::InProgress),
        "All claimed artists should be IN_PROGRESS"
    );
}

#[tokio::test]
#[ignore]
async fn artist_reset_in_progress_to_pending() {
    let (pool, _helper) = setup().await;
    let events = PgEventRepository::new(pool.clone());
    let artists = PgArtistRepository::new(pool.clone());

    let cmd = test_event_cmd("test-event-reset");
    events.upsert(cmd).await.expect("Setup failed");
    artists.claim_pending_batch(10).await.expect("Claim failed");

    let reset_count = artists
        .reset_in_progress_to_pending()
        .await
        .expect("Reset failed");
    assert!(reset_count > 0, "Expected at least one artist to be reset");

    // Verify they are PENDING again
    let all = artists
        .find_all(Pagination::default())
        .await
        .expect("Find failed");
    let in_progress = all
        .items
        .iter()
        .filter(|a| a.enrichment_status == EnrichmentStatus::InProgress)
        .count();
    assert_eq!(
        in_progress, 0,
        "No artists should be IN_PROGRESS after reset"
    );
}

// ---- AC4.3: Startup orphan reset ----

#[tokio::test]
#[ignore]
async fn startup_reset_clears_in_progress() {
    let (pool, _helper) = setup().await;
    let events = PgEventRepository::new(pool.clone());
    let artists = PgArtistRepository::new(pool.clone());

    // Create an artist via event upsert.
    events
        .upsert(test_event_cmd("test-event-orphan"))
        .await
        .unwrap();

    // Claim it (marks IN_PROGRESS).
    let claimed = artists.claim_pending_batch(10).await.unwrap();
    assert!(!claimed.is_empty());

    // Simulate orphan reset (as if app crashed and restarted).
    let orchestrator = EnrichmentOrchestrator::new(
        Arc::new(PgArtistRepository::new(pool.clone())),
        vec![], // No enrichers needed
    );
    orchestrator.reset_orphaned().await.unwrap();

    // Verify artists are back to PENDING.
    let all = artists
        .find_all(districtlive_server::domain::Pagination::default())
        .await
        .unwrap();
    let in_progress = all
        .items
        .iter()
        .filter(|a| a.enrichment_status == EnrichmentStatus::InProgress)
        .count();
    assert_eq!(
        in_progress, 0,
        "All IN_PROGRESS artists should be reset to PENDING"
    );
}

// ---- AC4.2: SKIPPED after max_attempts ----

#[tokio::test]
#[ignore]
async fn artist_marked_skipped_after_max_attempts() {
    let (pool, _helper) = setup().await;
    let events = PgEventRepository::new(pool.clone());
    let artists = PgArtistRepository::new(pool.clone());

    // Create an artist.
    events
        .upsert(test_event_cmd("test-event-skip"))
        .await
        .unwrap();
    let all = artists
        .find_all(districtlive_server::domain::Pagination::default())
        .await
        .unwrap();
    let artist_id = all.items[0].id;

    // A stub enricher that always returns no result (simulating no match).
    struct NullEnricher;
    #[async_trait::async_trait]
    impl ArtistEnricher for NullEnricher {
        fn source(&self) -> EnrichmentSource {
            EnrichmentSource::MusicBrainz
        }
        async fn enrich(&self, _name: &str) -> Result<Option<EnrichmentResult>, EnrichmentError> {
            Ok(None) // Never matches
        }
    }

    let orchestrator = EnrichmentOrchestrator::new(
        Arc::new(PgArtistRepository::new(pool.clone())),
        vec![Arc::new(NullEnricher)],
    );

    // Run 4 batches (max_attempts = 3, so 4th run should mark SKIPPED).
    for _ in 0..4 {
        orchestrator.enrich_batch().await.unwrap();
        // Reset eligible FAILED back to PENDING for retry.
        artists.reset_eligible_failed_to_pending(3).await.unwrap();
    }

    let artist = artists.find_by_id(artist_id).await.unwrap();
    assert_eq!(
        artist.enrichment_status,
        EnrichmentStatus::Skipped,
        "Artist should be SKIPPED after exceeding max_attempts"
    );
}

// ---- AC4.4: Transient error → FAILED (not SKIPPED) ----

#[tokio::test]
#[ignore]
async fn transient_error_marks_failed_not_skipped() {
    let (pool, _helper) = setup().await;
    let events = PgEventRepository::new(pool.clone());
    let artists = PgArtistRepository::new(pool.clone());

    events
        .upsert(test_event_cmd("test-event-failed"))
        .await
        .unwrap();

    struct ErrorEnricher;
    #[async_trait::async_trait]
    impl ArtistEnricher for ErrorEnricher {
        fn source(&self) -> EnrichmentSource {
            EnrichmentSource::MusicBrainz
        }
        async fn enrich(&self, _name: &str) -> Result<Option<EnrichmentResult>, EnrichmentError> {
            Err(EnrichmentError::Api("transient error".to_owned()))
        }
    }

    let orchestrator = EnrichmentOrchestrator::new(
        Arc::new(PgArtistRepository::new(pool.clone())),
        vec![Arc::new(ErrorEnricher)],
    );

    orchestrator.enrich_batch().await.unwrap();

    let all = artists
        .find_all(districtlive_server::domain::Pagination::default())
        .await
        .unwrap();
    let artist = &all.items[0];
    assert_eq!(
        artist.enrichment_status,
        EnrichmentStatus::Failed,
        "Transient error should mark FAILED not SKIPPED"
    );
}

// ---- Helpers ----

fn test_event_cmd(slug: &str) -> EventUpsertCommand {
    use time::OffsetDateTime;
    EventUpsertCommand {
        slug: slug.to_owned(),
        title: format!("Test Event {slug}"),
        description: None,
        start_time: OffsetDateTime::now_utc() + time::Duration::days(7),
        end_time: None,
        doors_time: None,
        venue_name: "Black Cat".to_owned(),
        venue_address: Some("1811 14th St NW, Washington, DC 20009".to_owned()),
        artist_names: vec!["Test Artist".to_owned()],
        min_price: Some(Decimal::new(1500, 2)), // $15.00
        max_price: None,
        price_tier: None,
        ticket_url: None,
        image_url: None,
        age_restriction: AgeRestriction::AllAges,
        source_attributions: vec![SourceAttribution {
            source_type: SourceType::Manual,
            source_identifier: None,
            source_url: None,
            confidence_score: Decimal::new(100, 2),
            source_id: None,
        }],
    }
}
