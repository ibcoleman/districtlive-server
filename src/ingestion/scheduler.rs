//! Ingestion scheduler — fires the ingestion pipeline on a cron schedule.

use std::sync::Arc;
use tokio_cron_scheduler::JobScheduler;

use crate::{
    config::Config, ingestion::orchestrator::IngestionOrchestrator, ports::SourceConnector,
};

/// Start the ingestion cron scheduler. Returns immediately; jobs run in background.
///
/// Starts two jobs:
/// 1. API cron (`config.ingestion_api_cron`): Ticketmaster, Bandsintown, Dice.fm
/// 2. Scraper cron (`config.ingestion_scraper_cron`): all venue website scrapers
///
/// No-op if `config.ingestion_enabled` is false.
pub async fn start_ingestion_scheduler(
    config: Arc<Config>,
    orchestrator: Arc<IngestionOrchestrator>,
    api_connectors: Vec<Arc<dyn SourceConnector>>,
    scraper_connectors: Vec<Arc<dyn SourceConnector>>,
) -> anyhow::Result<JobScheduler> {
    let sched = JobScheduler::new().await?;

    // API connectors job
    {
        let orchestrator = orchestrator.clone();
        let connectors = api_connectors.clone();
        let cron = config.ingestion_api_cron.clone();
        sched.add(
            tokio_cron_scheduler::Job::new_async(&cron, move |_uuid, _l| {
                let orchestrator = orchestrator.clone();
                let connectors = connectors.clone();
                Box::pin(async move {
                    tracing::info!("Ingestion scheduler: running API connectors");
                    for connector in &connectors {
                        if let Err(e) = orchestrator.run_connector(connector.as_ref()).await {
                            tracing::error!(error = %e, connector = connector.source_id(), "Connector failed");
                        }
                    }
                })
            })?
        )
        .await?;
    }

    // Scraper connectors job
    {
        let orchestrator = orchestrator.clone();
        let connectors = scraper_connectors.clone();
        let cron = config.ingestion_scraper_cron.clone();
        sched.add(
            tokio_cron_scheduler::Job::new_async(&cron, move |_uuid, _l| {
                let orchestrator = orchestrator.clone();
                let connectors = connectors.clone();
                Box::pin(async move {
                    tracing::info!("Ingestion scheduler: running scraper connectors");
                    for connector in &connectors {
                        if let Err(e) = orchestrator.run_connector(connector.as_ref()).await {
                            tracing::error!(error = %e, connector = connector.source_id(), "Connector failed");
                        }
                    }
                })
            })?
        )
        .await?;
    }

    sched.start().await?;
    tracing::info!(
        api_cron = %config.ingestion_api_cron,
        scraper_cron = %config.ingestion_scraper_cron,
        "Ingestion scheduler started"
    );
    Ok(sched)
}
