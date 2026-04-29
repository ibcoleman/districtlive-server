use districtlive_server::{
    adapters::{
        connect, PgArtistRepository, PgEventRepository, PgFeaturedEventRepository,
        PgIngestionRunRepository, PgSourceRepository, PgVenueRepository,
    },
    config::Config,
    http::{router, AppState},
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

    let state = AppState {
        config: config.clone(),
        venues: Arc::new(PgVenueRepository::new(pool.clone())),
        artists: Arc::new(PgArtistRepository::new(pool.clone())),
        events: Arc::new(PgEventRepository::new(pool.clone())),
        featured: Arc::new(PgFeaturedEventRepository::new(pool.clone())),
        sources: Arc::new(PgSourceRepository::new(pool.clone())),
        ingestion_runs: Arc::new(PgIngestionRunRepository::new(pool.clone())),
    };

    let bind_addr = config.bind_addr;
    let app = router(state);

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
