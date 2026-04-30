//! MusicBrainz artist enricher.
//!
//! Rate-limited to 1 request per second per MusicBrainz terms of service.
//! Uses Jaro-Winkler similarity to validate name matches.

use async_trait::async_trait;
use reqwest::Client;
use strsim::jaro_winkler;

use crate::{
    config::Config,
    domain::{
        artist::{EnrichmentResult, EnrichmentSource},
        error::EnrichmentError,
    },
    ports::ArtistEnricher,
};

/// MusicBrainz search API endpoint.
const MB_SEARCH_URL: &str = "https://musicbrainz.org/ws/2/artist/";

/// MusicBrainz server-side relevance score threshold (0–100).
/// Responses with score below this are not considered matches.
const MB_SERVER_SCORE_THRESHOLD: u32 = 80;

pub struct MusicBrainzEnricher {
    client: Client,
    confidence_threshold: f64,
    user_agent: String,
}

impl MusicBrainzEnricher {
    pub fn new(client: Client, config: &Config) -> Self {
        Self {
            client,
            confidence_threshold: config.musicbrainz_confidence_threshold,
            user_agent: format!(
                "districtlive-server/{} (https://districtlive.com)",
                env!("CARGO_PKG_VERSION")
            ),
        }
    }

    /// Parse a MusicBrainz search response JSON for a given artist name.
    /// Exposed for testing without HTTP calls.
    pub fn parse_response(
        json: &serde_json::Value,
        queried_name: &str,
        confidence_threshold: f64,
    ) -> Option<EnrichmentResult> {
        let artists = json.get("artists")?.as_array()?;
        let top = artists.first()?;

        let server_score = top.get("score").and_then(|s| s.as_u64()).unwrap_or(0) as u32;

        if server_score < MB_SERVER_SCORE_THRESHOLD {
            return None;
        }

        let mb_name = top.get("name").and_then(|n| n.as_str())?;
        let confidence = jaro_winkler(&queried_name.to_lowercase(), &mb_name.to_lowercase());

        if confidence < confidence_threshold {
            return None;
        }

        let mbid = top.get("id").and_then(|i| i.as_str()).map(str::to_owned);
        let tags = top
            .get("tags")
            .and_then(|t| t.as_array())
            .map(|arr| {
                arr.iter()
                    .filter_map(|t| t.get("name").and_then(|n| n.as_str()).map(str::to_owned))
                    .collect::<Vec<_>>()
            })
            .unwrap_or_default();

        Some(EnrichmentResult {
            source: EnrichmentSource::MusicBrainz,
            canonical_name: Some(mb_name.to_owned()),
            external_id: mbid,
            tags,
            image_url: None, // MusicBrainz does not provide images in search
            confidence,
        })
    }
}

#[async_trait]
impl ArtistEnricher for MusicBrainzEnricher {
    fn source(&self) -> EnrichmentSource {
        EnrichmentSource::MusicBrainz
    }

    async fn enrich(&self, name: &str) -> Result<Option<EnrichmentResult>, EnrichmentError> {
        let response = self
            .client
            .get(MB_SEARCH_URL)
            .header("User-Agent", &self.user_agent)
            .query(&[
                ("query", name),
                ("fmt", "json"),
                ("inc", "tags"), // Include tag data in response
                ("limit", "5"),
            ])
            .send()
            .await
            .map_err(EnrichmentError::Http)?;

        if !response.status().is_success() {
            return Err(EnrichmentError::Api(format!(
                "MusicBrainz returned status {}",
                response.status()
            )));
        }

        let json: serde_json::Value = response.json().await.map_err(EnrichmentError::Http)?;

        Ok(Self::parse_response(&json, name, self.confidence_threshold))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn parse_response_returns_result_when_score_and_confidence_pass() {
        let json = json!({
            "artists": [{
                "id": "some-mbid",
                "name": "Radiohead",
                "score": 100,
                "tags": [{"name": "rock"}, {"name": "alternative"}]
            }]
        });

        let result = MusicBrainzEnricher::parse_response(&json, "Radiohead", 0.7);
        let result = result.expect("should have a result");

        assert_eq!(result.source, EnrichmentSource::MusicBrainz);
        assert_eq!(result.canonical_name, Some("Radiohead".to_owned()));
        assert_eq!(result.external_id, Some("some-mbid".to_owned()));
        assert_eq!(result.tags, vec!["rock", "alternative"]);
        assert!(result.confidence > 0.7);
        assert!(result.image_url.is_none());
    }

    #[test]
    fn parse_response_returns_none_when_server_score_below_threshold() {
        let json = json!({
            "artists": [{
                "id": "some-mbid",
                "name": "Radiohead",
                "score": 50, // Below MB_SERVER_SCORE_THRESHOLD (80)
                "tags": []
            }]
        });

        let result = MusicBrainzEnricher::parse_response(&json, "Radiohead", 0.7);
        assert!(result.is_none(), "Should return None for low server score");
    }

    #[test]
    fn parse_response_returns_none_when_jaro_winkler_below_threshold() {
        let json = json!({
            "artists": [{
                "id": "some-mbid",
                "name": "Totally Different Artist",
                "score": 95,
                "tags": []
            }]
        });

        let result = MusicBrainzEnricher::parse_response(&json, "Radiohead", 0.9);
        assert!(
            result.is_none(),
            "Should return None when name similarity too low"
        );
    }

    #[test]
    fn parse_response_returns_none_for_empty_artists_array() {
        let json = json!({ "artists": [] });
        let result = MusicBrainzEnricher::parse_response(&json, "Radiohead", 0.7);
        assert!(result.is_none());
    }
}
