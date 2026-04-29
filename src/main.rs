use districtlive_server::{
    adapters::{
        connect, PgArtistRepository, PgEventRepository, PgFeaturedEventRepository,
        PgIngestionRunRepository, PgSourceRepository, PgVenueRepository,
    },
    config::Config,
    http::{create_router, AppState},
};
use std::sync::Arc;
use tokio::signal;
use tracing::info;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    let config = Arc::new(Config::from_env()?);
    let pool = Arc::new(connect(&config.database_url).await?);

    let http_client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .user_agent(format!(
            "districtlive-server/{} (https://districtlive.com)",
            env!("CARGO_PKG_VERSION")
        ))
        .build()
        .expect("Failed to build HTTP client");

    let events_repo = Arc::new(PgEventRepository::new(pool.clone()));
    let sources_repo = Arc::new(PgSourceRepository::new(pool.clone()));
    let ingestion_runs_repo = Arc::new(PgIngestionRunRepository::new(pool.clone()));

    let (ingestion_orchestrator, connectors) = if config.ingestion_enabled {
        use districtlive_server::ingestion::orchestrator::IngestionOrchestrator;
        let orchestrator = Arc::new(IngestionOrchestrator::new(
            events_repo.clone(),
            ingestion_runs_repo.clone(),
            sources_repo.clone(),
        ));
        let (api_connectors, scraper_connectors) = build_connectors(&config, &http_client);
        let mut all_connectors = api_connectors;
        all_connectors.extend(scraper_connectors);
        (Some(orchestrator), all_connectors)
    } else {
        (None, vec![])
    };

    let state = AppState {
        config: config.clone(),
        venues: Arc::new(PgVenueRepository::new(pool.clone())),
        artists: Arc::new(PgArtistRepository::new(pool.clone())),
        events: events_repo,
        featured: Arc::new(PgFeaturedEventRepository::new(pool.clone())),
        sources: sources_repo,
        ingestion_runs: ingestion_runs_repo,
        http_client: http_client.clone(),
        ingestion_orchestrator,
        connectors,
    };

    let bind_addr = config.bind_addr;
    let app = create_router(state);

    let listener = tokio::net::TcpListener::bind(bind_addr).await?;
    info!(%bind_addr, "serving");

    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await?;

    Ok(())
}

async fn shutdown_signal() {
    let ctrl_c = async {
        // Signal handler installation cannot fail at startup; panic is correct if it does.
        signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        // Signal handler installation cannot fail at startup; panic is correct if it does.
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("failed to install SIGTERM handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => info!("received Ctrl+C"),
        _ = terminate => info!("received SIGTERM"),
    }
}

type ConnectorList = Vec<Arc<dyn districtlive_server::ports::SourceConnector>>;

fn build_connectors(config: &Config, client: &reqwest::Client) -> (ConnectorList, ConnectorList) {
    use districtlive_server::adapters::connectors::*;

    let mut api_connectors: ConnectorList = Vec::new();
    let mut scraper_connectors: ConnectorList = Vec::new();

    // API connectors (Ticketmaster, Bandsintown, Dice.fm)
    if let Some(conn) = TicketmasterConnector::new(client.clone(), config) {
        api_connectors.push(Arc::new(conn));
    }
    if let Some(conn) = BandsintownConnector::new(client.clone(), config) {
        api_connectors.push(Arc::new(conn));
    }

    // Scraper connectors (all 7 venue websites)
    scraper_connectors.push(Arc::new(BlackCatScraper::new(client.clone())));
    scraper_connectors.push(Arc::new(Dc9Scraper::new(client.clone())));
    scraper_connectors.push(Arc::new(CometPingPongScraper::new(client.clone())));
    scraper_connectors.push(Arc::new(PieShopScraper::new(client.clone())));
    scraper_connectors.push(Arc::new(RhizomeDcScraper::new(client.clone())));
    scraper_connectors.push(Arc::new(SevenDrumCityScraper::new(client.clone())));
    scraper_connectors.push(Arc::new(UnionStagePresentsScraper::new(client.clone())));

    (api_connectors, scraper_connectors)
}
