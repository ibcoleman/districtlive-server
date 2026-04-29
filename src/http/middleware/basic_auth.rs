//! HTTP Basic authentication Tower middleware for the admin API.
//!
//! Returns 401 Unauthorized for:
//! - Missing `Authorization` header
//! - Malformed `Authorization` header
//! - Incorrect username or password

use axum::{
    extract::{Request, State},
    middleware::Next,
    response::Response,
};

use crate::http::error::ApiError;
use crate::http::AppState;

/// Tower middleware: validate HTTP Basic auth against Config admin credentials.
///
/// Apply to admin routes via:
/// ```rust
/// admin_router.route_layer(axum::middleware::from_fn_with_state(state, require_basic_auth))
/// ```
pub async fn require_basic_auth(
    State(state): State<AppState>,
    request: Request,
    next: Next,
) -> Result<Response, ApiError> {
    let auth_header = request
        .headers()
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or(ApiError::Unauthorized)?;

    // Parse "Basic <base64>" header
    let credentials = parse_basic_auth(auth_header).ok_or(ApiError::Unauthorized)?;

    if credentials.0 == state.config.admin_username
        && credentials.1 == state.config.admin_password
    {
        Ok(next.run(request).await)
    } else {
        Err(ApiError::Unauthorized)
    }
}

/// Parse `Authorization: Basic <base64(user:pass)>` header.
/// Returns `(username, password)` or `None` if malformed.
fn parse_basic_auth(header: &str) -> Option<(String, String)> {
    let encoded = header.strip_prefix("Basic ")?;
    let decoded = base64_decode(encoded)?;
    let s = std::str::from_utf8(&decoded).ok()?;
    let (user, pass) = s.split_once(':')?;
    Some((user.to_owned(), pass.to_owned()))
}

fn base64_decode(s: &str) -> Option<Vec<u8>> {
    // Use the base64 crate already in the dependency graph via sqlx/rustls
    // Decode standard base64 (with padding)
    let engine = base64::engine::general_purpose::STANDARD;
    base64::Engine::decode(&engine, s).ok()
}
