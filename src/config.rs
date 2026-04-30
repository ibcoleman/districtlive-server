//! Application configuration loaded from environment variables.
//!
//! All field names map to their uppercase `SCREAMING_SNAKE_CASE` env var equivalent
//! (e.g., `database_url` ← `DATABASE_URL`). Optional fields use `Option<T>` or
//! have sensible defaults for local development.
// pattern: Imperative Shell

use anyhow::Context as _;
use std::{env, net::SocketAddr};

#[derive(Clone, Debug)]
pub struct Config {
    // --- Core ---
    pub database_url: String,
    pub bind_addr: SocketAddr,

    // --- Admin ---
    /// HTTP Basic auth username for /api/admin/* routes.
    pub admin_username: String,
    /// HTTP Basic auth password for /api/admin/* routes.
    pub admin_password: String,

    // --- Ingestion ---
    pub ingestion_enabled: bool,
    /// Cron expression for API-based connectors (Ticketmaster, Bandsintown, Dice.fm).
    /// Default: every 6 hours.
    pub ingestion_api_cron: String,
    /// Cron expression for scraper-based connectors (venue websites).
    /// Default: every 6 hours.
    pub ingestion_scraper_cron: String,

    // --- Connectors ---
    pub ticketmaster_api_key: Option<String>,
    pub bandsintown_app_id: Option<String>,
    /// Comma-separated Dice.fm venue slugs to ingest (e.g. "black-cat,dc9").
    pub dicefm_venue_slugs: Vec<String>,

    // --- Enrichment ---
    pub enrichment_enabled: bool,
    /// Cron expression for artist enrichment batches. Default: every 2 hours.
    pub enrichment_cron: String,
    /// MusicBrainz name-match score threshold (0.0–1.0). Default: 0.7.
    pub musicbrainz_confidence_threshold: f64,
    pub spotify_enabled: bool,
    pub spotify_client_id: Option<String>,
    pub spotify_client_secret: Option<String>,

    // --- Notifications ---
    pub discord_webhook_url: Option<String>,
}

impl Config {
    /// Load configuration from environment variables.
    ///
    /// Required variables: `DATABASE_URL`.
    /// All others have defaults suitable for local development.
    pub fn from_env() -> anyhow::Result<Self> {
        Ok(Self {
            database_url: required("DATABASE_URL")?,
            bind_addr: env::var("BIND_ADDR")
                .unwrap_or_else(|_| "0.0.0.0:8080".to_owned())
                .parse::<SocketAddr>()
                .context("Invalid BIND_ADDR — expected format: host:port")?,
            admin_username: env::var("ADMIN_USERNAME").unwrap_or_else(|_| "admin".to_owned()),
            admin_password: env::var("ADMIN_PASSWORD").unwrap_or_else(|_| "changeme".to_owned()),
            ingestion_enabled: bool_flag("INGESTION_ENABLED"),
            ingestion_api_cron: env::var("INGESTION_API_CRON")
                .unwrap_or_else(|_| "0 0 */6 * * *".to_owned()),
            ingestion_scraper_cron: env::var("INGESTION_SCRAPER_CRON")
                .unwrap_or_else(|_| "0 30 */6 * * *".to_owned()),
            ticketmaster_api_key: env::var("TICKETMASTER_API_KEY").ok(),
            bandsintown_app_id: env::var("BANDSINTOWN_APP_ID").ok(),
            dicefm_venue_slugs: env::var("DICEFM_VENUE_SLUGS")
                .map(|s| {
                    s.split(',')
                        .map(str::trim)
                        .filter(|s| !s.is_empty())
                        .map(str::to_owned)
                        .collect()
                })
                .unwrap_or_default(),
            enrichment_enabled: bool_flag("ENRICHMENT_ENABLED"),
            enrichment_cron: env::var("ENRICHMENT_CRON")
                .unwrap_or_else(|_| "0 0 */2 * * *".to_owned()),
            musicbrainz_confidence_threshold: env::var("MUSICBRAINZ_CONFIDENCE_THRESHOLD")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(0.7),
            spotify_enabled: bool_flag("SPOTIFY_ENABLED"),
            spotify_client_id: env::var("SPOTIFY_CLIENT_ID").ok(),
            spotify_client_secret: env::var("SPOTIFY_CLIENT_SECRET").ok(),
            discord_webhook_url: env::var("DISCORD_WEBHOOK_URL").ok(),
        })
    }
}

/// Test-only constructor with sensible defaults. Avoids reading environment variables.
///
/// Used by `tests/support/mod.rs` to build a test AppState without live config.
/// `SocketAddr` does not implement `Default`, so a blanket `#[derive(Default)]` will not
/// compile — this method is the intended substitute.
#[cfg(any(test, feature = "test-helpers"))]
impl Config {
    pub fn test_default() -> Self {
        Self {
            database_url: "postgres://test:test@localhost/test".to_owned(),
            bind_addr: "127.0.0.1:0".parse().expect("valid addr"),
            admin_username: "testuser".to_owned(),
            admin_password: "testpass".to_owned(),
            ingestion_enabled: false,
            ingestion_api_cron: "0 0 * * * *".to_owned(),
            ingestion_scraper_cron: "0 0 * * * *".to_owned(),
            ticketmaster_api_key: None,
            bandsintown_app_id: None,
            dicefm_venue_slugs: vec![],
            enrichment_enabled: false,
            enrichment_cron: "0 0 * * * *".to_owned(),
            musicbrainz_confidence_threshold: 0.9,
            spotify_enabled: false,
            spotify_client_id: None,
            spotify_client_secret: None,
            discord_webhook_url: None,
        }
    }
}

fn required(name: &str) -> anyhow::Result<String> {
    env::var(name)
        .map_err(|_| anyhow::anyhow!("Required environment variable `{}` is not set", name))
}

/// Returns `true` if the env var is set to `"true"`, `"1"`, or `"yes"` (case-insensitive).
fn bool_flag(name: &str) -> bool {
    matches!(
        env::var(name)
            .as_deref()
            .map(str::to_ascii_lowercase)
            .as_deref(),
        Ok("true") | Ok("1") | Ok("yes")
    )
}
