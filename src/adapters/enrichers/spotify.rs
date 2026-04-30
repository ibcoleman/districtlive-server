//! Spotify artist enricher.
//!
//! Disabled by default (`Config.spotify_enabled = false`).
//! Uses OAuth2 client credentials flow with token caching.
//! Handles HTTP 429 rate limiting with Retry-After backoff.

use async_trait::async_trait;
use reqwest::Client;
use serde::Deserialize;
use std::sync::Arc;
use strsim::jaro_winkler;
use tokio::sync::Mutex;
use tokio::time::{sleep, Duration};

use crate::{
    config::Config,
    domain::{
        artist::{EnrichmentResult, EnrichmentSource},
        error::EnrichmentError,
    },
    ports::ArtistEnricher,
};

const SPOTIFY_TOKEN_URL: &str = "https://accounts.spotify.com/api/token";
const SPOTIFY_SEARCH_URL: &str = "https://api.spotify.com/v1/search";
const SPOTIFY_CONFIDENCE_THRESHOLD: f64 = 0.90;
const MAX_RETRIES: u32 = 3;
/// Expire cached token 60 seconds early as a safety buffer.
const TOKEN_EXPIRY_BUFFER_SECS: u64 = 60;

#[derive(Debug)]
struct CachedToken {
    access_token: String,
    /// Unix timestamp when this token expires (after applying expiry buffer).
    expires_at: u64,
}

impl CachedToken {
    fn is_valid(&self) -> bool {
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        self.expires_at > now
    }
}

pub struct SpotifyEnricher {
    client: Client,
    client_id: String,
    client_secret: String,
    confidence_threshold: f64,
    token_cache: Arc<Mutex<Option<CachedToken>>>,
}

impl SpotifyEnricher {
    /// Returns `Some(Self)` only when Spotify is enabled and credentials are configured.
    pub fn new(client: Client, config: &Config) -> Option<Self> {
        if !config.spotify_enabled {
            return None;
        }
        let client_id = config.spotify_client_id.clone()?;
        let client_secret = config.spotify_client_secret.clone()?;
        Some(Self {
            client,
            client_id,
            client_secret,
            confidence_threshold: SPOTIFY_CONFIDENCE_THRESHOLD,
            token_cache: Arc::new(Mutex::new(None)),
        })
    }

    async fn get_token(&self) -> Result<String, EnrichmentError> {
        let mut cache = self.token_cache.lock().await;
        if let Some(token) = cache.as_ref() {
            if token.is_valid() {
                return Ok(token.access_token.clone());
            }
        }

        #[derive(Deserialize)]
        struct TokenResponse {
            access_token: String,
            expires_in: u64,
        }

        let response: TokenResponse = self
            .client
            .post(SPOTIFY_TOKEN_URL)
            .basic_auth(&self.client_id, Some(&self.client_secret))
            .form(&[("grant_type", "client_credentials")])
            .send()
            .await
            .map_err(EnrichmentError::Http)?
            .json()
            .await
            .map_err(EnrichmentError::Http)?;

        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        *cache = Some(CachedToken {
            access_token: response.access_token.clone(),
            expires_at: now + response.expires_in.saturating_sub(TOKEN_EXPIRY_BUFFER_SECS),
        });

        Ok(response.access_token)
    }

    async fn search(&self, name: &str, token: &str) -> Result<serde_json::Value, EnrichmentError> {
        let mut attempts = 0;
        loop {
            let response = self
                .client
                .get(SPOTIFY_SEARCH_URL)
                .query(&[("q", name), ("type", "artist"), ("limit", "5")])
                .bearer_auth(token)
                .send()
                .await
                .map_err(EnrichmentError::Http)?;

            if response.status() == reqwest::StatusCode::TOO_MANY_REQUESTS {
                attempts += 1;
                if attempts >= MAX_RETRIES {
                    return Err(EnrichmentError::RateLimited);
                }
                let retry_after = response
                    .headers()
                    .get("Retry-After")
                    .and_then(|v| v.to_str().ok())
                    .and_then(|s| s.parse::<u64>().ok())
                    .unwrap_or(1);
                tracing::warn!(retry_after, "Spotify rate limited — waiting before retry");
                sleep(Duration::from_secs(retry_after)).await;
                continue;
            }

            if !response.status().is_success() {
                return Err(EnrichmentError::Api(format!(
                    "Spotify returned status {}",
                    response.status()
                )));
            }

            return response.json().await.map_err(EnrichmentError::Http);
        }
    }
}

#[async_trait]
impl ArtistEnricher for SpotifyEnricher {
    fn source(&self) -> EnrichmentSource {
        EnrichmentSource::Spotify
    }

    async fn enrich(&self, name: &str) -> Result<Option<EnrichmentResult>, EnrichmentError> {
        let token = self.get_token().await?;
        let json = self.search(name, &token).await?;

        let item = match json
            .get("artists")
            .and_then(|a| a.get("items"))
            .and_then(|i| i.as_array())
            .and_then(|arr| arr.first())
        {
            Some(i) => i,
            None => return Ok(None),
        };

        let spotify_name = match item.get("name").and_then(|n| n.as_str()) {
            Some(n) => n,
            None => return Ok(None),
        };

        let confidence = jaro_winkler(&name.to_lowercase(), &spotify_name.to_lowercase());

        if confidence < self.confidence_threshold {
            return Ok(None);
        }

        let spotify_id = item.get("id").and_then(|i| i.as_str()).map(str::to_owned);
        let genres = item
            .get("genres")
            .and_then(|g| g.as_array())
            .map(|arr| {
                arr.iter()
                    .filter_map(|g| g.as_str().map(str::to_owned))
                    .collect::<Vec<_>>()
            })
            .unwrap_or_default();
        let image_url = item
            .get("images")
            .and_then(|i| i.as_array())
            .and_then(|arr| arr.first())
            .and_then(|img| img.get("url"))
            .and_then(|u| u.as_str())
            .map(str::to_owned);

        Ok(Some(EnrichmentResult {
            source: EnrichmentSource::Spotify,
            canonical_name: Some(spotify_name.to_owned()),
            external_id: spotify_id,
            tags: genres,
            image_url,
            confidence,
        }))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_returns_none_when_spotify_disabled() {
        let config = Config::test_default(); // spotify_enabled = false by default
        let client = Client::new();
        assert!(
            SpotifyEnricher::new(client, &config).is_none(),
            "SpotifyEnricher::new should return None when spotify_enabled = false"
        );
    }

    #[test]
    fn new_returns_none_when_credentials_missing() {
        // Even if spotify_enabled is true, missing credentials should return None
        let mut config = Config::test_default();
        config.spotify_enabled = true;
        // spotify_client_id and spotify_client_secret remain None
        let client = Client::new();
        assert!(
            SpotifyEnricher::new(client, &config).is_none(),
            "SpotifyEnricher::new should return None when credentials are missing"
        );
    }
}
