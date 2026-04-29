#![cfg(feature = "test-helpers")]

use axum::http::StatusCode;
use axum_test::TestServer;

mod support;
use support::test_state;

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

// --- AC2.8: Malformed date_from returns 400 ---
#[tokio::test]
async fn list_events_bad_date_returns_400() {
    let server = test_server();
    server
        .get("/api/events?date_from=not-a-date")
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

fn base64_encode(s: &str) -> String {
    use base64::Engine;
    base64::engine::general_purpose::STANDARD.encode(s.as_bytes())
}
