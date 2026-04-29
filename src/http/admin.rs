//! Admin API handlers. All routes require HTTP Basic auth (enforced by middleware).

use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use serde::Deserialize;
use serde_json::json;
use uuid::Uuid;

use crate::{
    domain::featured_event::{FeaturedEvent, FeaturedEventId},
    http::{
        dto::{FeaturedEventDto, IngestionRunDto, SourceHealthDto},
        error::ApiError,
        AppState,
    },
};

pub async fn list_sources(
    State(state): State<AppState>,
) -> Result<Json<Vec<SourceHealthDto>>, ApiError> {
    let sources = state.sources.find_all().await?;
    Ok(Json(
        sources.iter().map(SourceHealthDto::from_source).collect(),
    ))
}

pub async fn get_source_history(
    State(state): State<AppState>,
    Path(source_id): Path<Uuid>,
) -> Result<Json<Vec<IngestionRunDto>>, ApiError> {
    use crate::domain::source::SourceId;
    let runs = state
        .ingestion_runs
        .find_by_source_id_desc(SourceId(source_id))
        .await?;
    Ok(Json(runs.iter().map(IngestionRunDto::from_run).collect()))
}

pub async fn trigger_all_ingestion(
    State(state): State<AppState>,
) -> Result<Json<serde_json::Value>, ApiError> {
    if !state.config.ingestion_enabled {
        return Err(ApiError::Ingestion(
            crate::domain::error::IngestionError::Disabled,
        ));
    }

    let orchestrator = state
        .ingestion_orchestrator
        .as_ref()
        .ok_or_else(|| ApiError::Internal("Orchestrator not configured".into()))?;

    use crate::ingestion::orchestrator::IngestionStats;
    let mut total = IngestionStats {
        events_fetched: 0,
        events_created: 0,
        events_updated: 0,
        events_deduplicated: 0,
    };
    for connector in &state.connectors {
        match orchestrator.run_connector(connector.as_ref()).await {
            Ok(stats) => {
                total.events_fetched += stats.events_fetched;
                total.events_created += stats.events_created;
                total.events_updated += stats.events_updated;
                total.events_deduplicated += stats.events_deduplicated;
            }
            Err(e) => tracing::error!(error = %e, "Connector failed during manual trigger"),
        }
    }

    Ok(Json(json!({
        "status": "complete",
        "events_fetched": total.events_fetched,
        "events_created": total.events_created,
        "events_updated": total.events_updated,
        "events_deduplicated": total.events_deduplicated,
    })))
}

pub async fn trigger_source_ingestion(
    State(state): State<AppState>,
    Path(source_id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, ApiError> {
    if !state.config.ingestion_enabled {
        return Err(ApiError::Ingestion(
            crate::domain::error::IngestionError::Disabled,
        ));
    }
    Ok(Json(json!({
        "status": "triggered",
        "source_id": source_id.to_string()
    })))
}

pub async fn get_featured_history(
    State(state): State<AppState>,
) -> Result<Json<Vec<FeaturedEventDto>>, ApiError> {
    let featured_list = state.featured.find_all_desc().await?;
    let mut dtos = Vec::with_capacity(featured_list.len());
    for f in &featured_list {
        let event = state.events.find_by_id(f.event_id).await?;
        use crate::http::dto::{EventDetailDto, EventDto};
        let event_dto = EventDto::from_event(&event);
        dtos.push(FeaturedEventDto {
            id: f.id.0,
            event: EventDetailDto {
                event: event_dto,
                description: event.description,
                end_time: event.end_time,
                sources: vec![],
                related_events: vec![],
            },
            blurb: f.blurb.clone(),
            created_at: f.created_at,
            created_by: f.created_by.clone(),
        });
    }
    Ok(Json(dtos))
}

#[derive(Deserialize)]
pub struct CreateFeaturedRequest {
    pub event_id: Uuid,
    pub blurb: String,
}

pub async fn create_featured(
    State(state): State<AppState>,
    Json(body): Json<CreateFeaturedRequest>,
) -> Result<(StatusCode, Json<FeaturedEventDto>), ApiError> {
    if body.blurb.trim().is_empty() {
        return Err(ApiError::BadRequest("blurb cannot be blank".to_owned()));
    }

    use crate::domain::event::EventId;
    // Verify the event exists — returns 404 if not
    let event = state.events.find_by_id(EventId(body.event_id)).await?;

    let featured = FeaturedEvent {
        id: FeaturedEventId::new(),
        event_id: event.id,
        blurb: body.blurb.trim().to_owned(),
        created_at: time::OffsetDateTime::now_utc(),
        created_by: "admin".to_owned(),
    };

    let saved = state.featured.save(&featured).await?;

    use crate::http::dto::{EventDetailDto, EventDto};
    let event_dto = EventDto::from_event(&event);

    Ok((
        StatusCode::CREATED,
        Json(FeaturedEventDto {
            id: saved.id.0,
            event: EventDetailDto {
                event: event_dto,
                description: event.description,
                end_time: event.end_time,
                sources: vec![],
                related_events: vec![],
            },
            blurb: saved.blurb,
            created_at: saved.created_at,
            created_by: saved.created_by,
        }),
    ))
}
