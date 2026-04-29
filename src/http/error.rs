//! HTTP error type. Converts domain errors to HTTP responses.

use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;

use crate::domain::error::{EnrichmentError, IngestionError, RepoError};

#[derive(Debug, thiserror::Error)]
pub enum ApiError {
    #[error("bad request: {0}")]
    BadRequest(String),
    #[error("not found")]
    NotFound,
    #[error("unauthorized")]
    Unauthorized,
    #[error("internal server error: {0}")]
    Internal(String),
    #[error(transparent)]
    Repo(#[from] RepoError),
    #[error(transparent)]
    Ingestion(#[from] IngestionError),
}

impl From<EnrichmentError> for ApiError {
    fn from(e: EnrichmentError) -> Self {
        ApiError::Internal(e.to_string())
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, message) = match &self {
            ApiError::BadRequest(m) => (StatusCode::BAD_REQUEST, m.clone()),
            ApiError::NotFound => (StatusCode::NOT_FOUND, "not found".to_owned()),
            ApiError::Unauthorized => (StatusCode::UNAUTHORIZED, "unauthorized".to_owned()),
            ApiError::Internal(m) => (StatusCode::INTERNAL_SERVER_ERROR, m.clone()),
            ApiError::Repo(RepoError::NotFound) => (StatusCode::NOT_FOUND, "not found".to_owned()),
            ApiError::Repo(RepoError::Database(e)) => {
                tracing::error!("Database error: {e}");
                (StatusCode::INTERNAL_SERVER_ERROR, "database error".to_owned())
            }
            ApiError::Ingestion(IngestionError::Disabled) => {
                (StatusCode::BAD_REQUEST, "ingestion is disabled".to_owned())
            }
            ApiError::Ingestion(e) => {
                tracing::error!("Ingestion error: {e}");
                (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
            }
        };

        (status, Json(json!({ "error": message }))).into_response()
    }
}
