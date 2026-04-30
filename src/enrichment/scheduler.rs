//! Enrichment scheduler — fires enrichment batches on a cron schedule.
//!
// pattern: Imperative Shell

use std::sync::Arc;
use tokio_cron_scheduler::{Job, JobScheduler};

use crate::{config::Config, enrichment::orchestrator::EnrichmentOrchestrator};

/// Start the enrichment cron scheduler. Returns immediately; job runs in background.
///
/// No-op if `config.enrichment_enabled` is false.
pub async fn start_enrichment_scheduler(
    config: Arc<Config>,
    orchestrator: Arc<EnrichmentOrchestrator>,
) -> anyhow::Result<JobScheduler> {
    let sched = JobScheduler::new().await?;

    let orchestrator_clone = orchestrator.clone();
    let cron = config.enrichment_cron.clone();

    sched
        .add(Job::new_async(&cron, move |_uuid, _l| {
            let orchestrator = orchestrator_clone.clone();
            Box::pin(async move {
                match orchestrator.enrich_batch().await {
                    Ok(count) => tracing::info!(count, "Enrichment batch completed"),
                    Err(e) => tracing::error!(error = %e, "Enrichment batch failed"),
                }
            })
        })?)
        .await?;

    sched.start().await?;
    tracing::info!(cron = %config.enrichment_cron, "Enrichment scheduler started");
    Ok(sched)
}
