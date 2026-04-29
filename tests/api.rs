use axum_test::TestServer;
use districtlive_server::config::Config;
use districtlive_server::http::{router, AppState};
use std::sync::Arc;

#[tokio::test]
async fn healthz_returns_ok() {
    // Arrange
    let state = AppState {
        config: Arc::new(Config::test_default()),
    };
    let app = router(state);
    let server = TestServer::new(app).expect("failed to create test server");

    // Act
    let resp = server.get("/healthz").await;

    // Assert
    resp.assert_status_ok();
    resp.assert_text("ok");
}
