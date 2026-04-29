//! Ingestion orchestrator — runs the full fetch → normalize → filter → deduplicate → upsert pipeline
//! for a single source connector.

use std::sync::Arc;

use crate::{
    domain::{error::IngestionError, event::EventUpsertCommand},
    ingestion::{deduplication::DeduplicationService, normalization::NormalizationService},
    ports::{
        event_repository::UpsertResult, EventRepository, IngestionRunRepository, SourceConnector,
        SourceRepository,
    },
};

pub struct IngestionStats {
    pub events_fetched: i32,
    pub events_created: i32,
    pub events_updated: i32,
    pub events_deduplicated: i32,
}

pub struct IngestionOrchestrator {
    pub events: Arc<dyn EventRepository>,
    pub ingestion_runs: Arc<dyn IngestionRunRepository>,
    pub sources: Arc<dyn SourceRepository>,
    pub normalization: NormalizationService,
    pub deduplication: DeduplicationService,
}

impl IngestionOrchestrator {
    pub fn new(
        events: Arc<dyn EventRepository>,
        ingestion_runs: Arc<dyn IngestionRunRepository>,
        sources: Arc<dyn SourceRepository>,
    ) -> Self {
        Self {
            events,
            ingestion_runs,
            sources,
            normalization: NormalizationService,
            deduplication: DeduplicationService,
        }
    }

    /// Run the full ingestion pipeline for one connector.
    pub async fn run_connector(
        &self,
        connector: &dyn SourceConnector,
    ) -> Result<IngestionStats, IngestionError> {
        // Find source record (if it exists — log warning if not found, continue anyway)
        let source = self
            .sources
            .find_by_name(connector.source_id())
            .await
            .ok()
            .flatten();
        let source_id = source.as_ref().map(|s| s.id);

        // Create ingestion run record
        let run = if let Some(sid) = source_id {
            // IngestionError::Repo is a From<RepoError> conversion added in Phase 2.
            Some(self.ingestion_runs.create(sid).await?)
        } else {
            tracing::warn!(
                connector = connector.source_id(),
                "No source record found for connector — stats will not be persisted"
            );
            None
        };

        let result = self.run_pipeline(connector, source_id).await;

        // Update run record with outcome
        if let Some(run) = run {
            match &result {
                Ok(stats) => {
                    let _ = self
                        .ingestion_runs
                        .mark_success(
                            run.id,
                            stats.events_fetched,
                            stats.events_created,
                            stats.events_updated,
                            stats.events_deduplicated,
                        )
                        .await;
                    if let Some(sid) = source_id {
                        let _ = self.sources.record_success(sid).await;
                    }
                }
                Err(e) => {
                    let _ = self
                        .ingestion_runs
                        .mark_failed(run.id, &e.to_string())
                        .await;
                    if let Some(sid) = source_id {
                        let _ = self.sources.record_failure(sid, &e.to_string()).await;
                    }
                }
            }
        }

        result
    }

    async fn run_pipeline(
        &self,
        connector: &dyn SourceConnector,
        source_id: Option<crate::domain::source::SourceId>,
    ) -> Result<IngestionStats, IngestionError> {
        // Step 1: Fetch
        let raw_events = connector.fetch().await?;
        let events_fetched = raw_events.len() as i32;
        tracing::info!(
            connector = connector.source_id(),
            count = events_fetched,
            "Fetched events"
        );

        if raw_events.is_empty() {
            return Ok(IngestionStats {
                events_fetched: 0,
                events_created: 0,
                events_updated: 0,
                events_deduplicated: 0,
            });
        }

        // Step 2: Normalize
        let normalized = self.normalization.normalize(raw_events);

        // Step 3: Filter placeholder titles
        let filtered: Vec<_> = normalized
            .into_iter()
            .filter(|e| {
                if NormalizationService::is_placeholder(&e.raw.title) {
                    tracing::debug!(title = %e.raw.title, "Filtering placeholder title");
                    false
                } else {
                    true
                }
            })
            .collect();

        // Step 4: Deduplicate
        let before_dedup = filtered.len();
        let deduped = self.deduplication.deduplicate(filtered);
        let events_deduplicated = (before_dedup - deduped.len()) as i32;

        // Step 5: Upsert each event
        let mut events_created = 0;
        let mut events_updated = 0;

        for deduped_event in deduped {
            use crate::domain::event::AgeRestriction;

            // Map age_restriction string to enum
            let age_restriction = match deduped_event.event.raw.age_restriction.as_deref() {
                Some(s) if s.to_lowercase().contains("18") => AgeRestriction::EighteenPlus,
                Some(s) if s.to_lowercase().contains("21") => AgeRestriction::TwentyOnePlus,
                _ => AgeRestriction::AllAges,
            };

            // Inject source_id into attributions
            let mut sources = deduped_event.sources;
            for s in &mut sources {
                s.source_id = source_id;
            }

            let cmd = EventUpsertCommand {
                slug: deduped_event.event.slug.clone(),
                title: deduped_event.event.raw.title.clone(),
                description: deduped_event.event.raw.description.clone(),
                start_time: deduped_event.event.raw.start_time,
                end_time: deduped_event.event.raw.end_time,
                doors_time: deduped_event.event.raw.doors_time,
                venue_name: deduped_event.event.raw.venue_name.clone(),
                venue_address: deduped_event.event.raw.venue_address.clone(),
                artist_names: deduped_event
                    .event
                    .raw
                    .artist_names
                    .iter()
                    .filter_map(|n| crate::ingestion::normalization::clean_artist_name(n))
                    .collect(),
                min_price: deduped_event.event.raw.min_price,
                max_price: deduped_event.event.raw.max_price,
                price_tier: None,
                ticket_url: deduped_event.event.raw.ticket_url.clone(),
                image_url: deduped_event.event.raw.image_url.clone(),
                age_restriction,
                source_attributions: sources,
            };

            match self.events.upsert(cmd).await {
                Ok(UpsertResult::Created) => events_created += 1,
                Ok(UpsertResult::Updated) => events_updated += 1,
                Err(e) => {
                    tracing::warn!(error = %e, "Event upsert failed — continuing");
                }
            }
        }

        Ok(IngestionStats {
            events_fetched,
            events_created,
            events_updated,
            events_deduplicated,
        })
    }
}
