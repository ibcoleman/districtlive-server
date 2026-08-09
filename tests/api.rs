#![cfg(feature = "test-helpers")]

use axum::http::StatusCode;
use axum_test::TestServer;

mod support;
use support::{seeded_test_state, test_state};

fn test_server() -> TestServer {
    let app = districtlive_server::http::create_router(test_state());
    TestServer::new(app).expect("Failed to create test server")
}

#[tokio::test]
async fn healthz_returns_ok() {
    let server = test_server();
    server.get("/healthz").await.assert_status_ok();
}

// --- AC5.4: Missing Authorization header returns 401 ---
#[tokio::test]
async fn admin_without_auth_returns_401() {
    let server = test_server();
    server
        .get("/api/admin/sources")
        .await
        .assert_status(StatusCode::UNAUTHORIZED);
}

// --- AC5.5: Wrong credentials return 401 ---
#[tokio::test]
async fn admin_wrong_credentials_returns_401() {
    let server = test_server();
    server
        .get("/api/admin/sources")
        .add_header("Authorization", "Basic d3Jvbmc6Y3JlZHM=") // wrong:creds in base64
        .await
        .assert_status(StatusCode::UNAUTHORIZED);
}

// --- AC5.1: Valid credentials return 200 ---
#[tokio::test]
async fn admin_valid_credentials_returns_200() {
    let server = test_server();
    // testuser:testpass in base64
    let creds = base64_encode("testuser:testpass");
    server
        .get("/api/admin/sources")
        .add_header("Authorization", &format!("Basic {creds}"))
        .await
        .assert_status_ok();
}

// --- AC2.7: Unknown event UUID returns 404 ---
#[tokio::test]
async fn get_event_unknown_id_returns_404() {
    let server = test_server();
    server
        .get("/api/events/00000000-0000-0000-0000-000000000001")
        .await
        .assert_status(StatusCode::NOT_FOUND);
}

// --- AC2.8: Malformed dateFrom returns 400 ---
#[tokio::test]
async fn list_events_bad_date_returns_400() {
    let server = test_server();
    server
        .get("/api/events?dateFrom=not-a-date")
        .await
        .assert_status(StatusCode::BAD_REQUEST);
}

// --- AC5.6: Blank blurb returns 400 ---
#[tokio::test]
async fn create_featured_blank_blurb_returns_400() {
    let server = test_server();
    let creds = base64_encode("testuser:testpass");
    server
        .post("/api/admin/featured")
        .add_header("Authorization", &format!("Basic {creds}"))
        .json(&serde_json::json!({
            "event_id": "00000000-0000-0000-0000-000000000001",
            "blurb": "   "
        }))
        .await
        .assert_status(StatusCode::BAD_REQUEST);
}

// --- AC5.7: Unknown event UUID returns 404 ---
#[tokio::test]
async fn create_featured_unknown_event_returns_404() {
    let server = test_server();
    let creds = base64_encode("testuser:testpass");
    server
        .post("/api/admin/featured")
        .add_header("Authorization", &format!("Basic {creds}"))
        .json(&serde_json::json!({
            "event_id": "00000000-0000-0000-0000-000000000001",
            "blurb": "A real blurb about this event"
        }))
        .await
        .assert_status(StatusCode::NOT_FOUND);
}

// --- AC3.8: Admin ingest trigger returns 400 when ingestion is disabled ---
//
// test_state() uses Config::test_default() which sets ingestion_enabled = false.
// The handler maps IngestionError::Disabled → 400 BAD_REQUEST.
#[tokio::test]
async fn admin_ingest_trigger_when_disabled_returns_400() {
    let server = test_server();
    let creds = base64_encode("testuser:testpass");
    server
        .post("/api/admin/ingest/trigger")
        .add_header("Authorization", &format!("Basic {creds}"))
        .await
        .assert_status(StatusCode::BAD_REQUEST);
}

fn base64_encode(s: &str) -> String {
    use base64::Engine;
    base64::engine::general_purpose::STANDARD.encode(s.as_bytes())
}

// ---- AC.3: /api/featured/current route returns 200 with seeded data ----

fn make_seeded_featured_state() -> districtlive_server::http::AppState {
    use districtlive_server::domain::event::{AgeRestriction, Event, EventId, EventStatus};
    use districtlive_server::domain::featured_event::{FeaturedEvent, FeaturedEventId};
    use time::OffsetDateTime;

    let event_id = EventId::new();
    let event = Event {
        id: event_id,
        title: "Test Featured Event".into(),
        slug: "test-featured-event".into(),
        description: Some("A great show".into()),
        start_time: OffsetDateTime::now_utc(),
        end_time: None,
        doors_time: None,
        min_price: None,
        max_price: None,
        price_tier: None,
        ticket_url: None,
        on_sale_date: None,
        sold_out: false,
        ticket_platform: None,
        image_url: None,
        age_restriction: AgeRestriction::AllAges,
        status: EventStatus::Active,
        venue_id: None,
        title_parsed: false,
        event_type: None,
        created_at: OffsetDateTime::now_utc(),
        updated_at: OffsetDateTime::now_utc(),
    };
    let featured = FeaturedEvent {
        id: FeaturedEventId::new(),
        event_id,
        blurb: "Don't miss this!".into(),
        created_at: OffsetDateTime::now_utc(),
        created_by: "test".into(),
    };
    seeded_test_state(featured, event)
}

#[tokio::test]
async fn test_featured_current_route() {
    let app = districtlive_server::http::create_router(make_seeded_featured_state());
    let server = TestServer::new(app).expect("Failed to create test server");

    let response = server.get("/api/featured/current").await;
    response.assert_status(StatusCode::OK);
    let body = response.json::<serde_json::Value>();
    // Verify JSON shape: should have id, event (object), blurb
    assert!(body.get("id").is_some(), "featured response should have id");
    assert!(
        body.get("blurb").is_some(),
        "featured response should have blurb"
    );
    assert!(
        body.get("event").is_some(),
        "featured response should have event object"
    );
    // Verify nested event has camelCase fields
    let event = &body["event"];
    assert!(
        event.get("startTime").is_some(),
        "event should have startTime"
    );
    assert!(
        event.get("createdAt").is_some(),
        "event should have createdAt"
    );
}

#[tokio::test]
async fn test_featured_current_unknown_subpath_returns_404() {
    let app = districtlive_server::http::create_router(make_seeded_featured_state());
    let server = TestServer::new(app).expect("Failed to create test server");
    // An unknown sub-path under /api/featured should return 404,
    // proving the route is registered at /api/featured/current specifically.
    server
        .get("/api/featured/unknown")
        .await
        .assert_status(StatusCode::NOT_FOUND);
}

// ---- AC.4: /api/events accepts venue, size, sort, dateFrom, dateTo params ----

#[tokio::test]
async fn test_events_query_params() {
    let server = test_server();
    // These params should be accepted (200), not silently ignored.
    server
        .get("/api/events?venue=some-slug&size=10&sort=createdAt,desc&dateFrom=2025-01-01T00:00:00Z&dateTo=2025-12-31T23:59:59Z")
        .await
        .assert_status(StatusCode::OK);
}

#[tokio::test]
async fn test_events_bad_date_from_returns_400() {
    // Proves dateFrom param is bound and parsed — invalid value yields 400,
    // not silently ignored (which would be 200).
    let server = test_server();
    server
        .get("/api/events?dateFrom=not-a-date")
        .await
        .assert_status(StatusCode::BAD_REQUEST);
}

// ---- AC.5: /api/venues accepts size param ----

#[tokio::test]
async fn test_venues_size_param() {
    let server = test_server();
    server
        .get("/api/venues?size=10")
        .await
        .assert_status(StatusCode::OK);
}
