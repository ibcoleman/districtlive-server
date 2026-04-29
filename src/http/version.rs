use axum::Json;
use serde_json::{json, Value};

pub async fn get_version() -> Json<Value> {
    Json(json!({
        "version": env!("CARGO_PKG_VERSION"),
        "build": "unknown",
        "commit": "unknown"
    }))
}
