//! Bandsintown API connector for DC music events.
// pattern: Imperative Shell

use async_trait::async_trait;
use reqwest::Client;
use rust_decimal::Decimal;
use serde_json::Value;
use time::OffsetDateTime;

use crate::{
    config::Config,
    domain::{error::IngestionError, event::RawEvent, source::SourceType},
    ports::SourceConnector,
};

pub struct BandsintownConnector {
    client: Client,
    app_id: String,
    base_url: String,
    seed_artists: Vec<String>,
}

impl BandsintownConnector {
    pub fn new(client: Client, config: &Config) -> Option<Self> {
        config.bandsintown_app_id.as_ref().map(|app_id| {
            // Seed artists for DC area (from Kotlin source: application.yml)
            let seed_artists = vec![
                "Fugazi".to_owned(),
                "Bad Brains".to_owned(),
                "Minor Threat".to_owned(),
            ];

            Self {
                client,
                app_id: app_id.clone(),
                base_url: "https://rest.bandsintown.com".to_owned(),
                seed_artists,
            }
        })
    }

    /// Parse JSON array response into RawEvents. Used by both fetch() and tests.
    pub fn parse_json(json_str: &str, artist: &str) -> Result<Vec<RawEvent>, IngestionError> {
        let root: Value = serde_json::from_str(json_str)
            .map_err(|e| IngestionError::Parse(format!("Invalid JSON: {}", e)))?;

        if !root.is_array() {
            return Err(IngestionError::Parse(
                "Expected array response but got object".to_owned(),
            ));
        }

        let empty_vec = vec![];
        let events_arr = root.as_array().unwrap_or(&empty_vec);
        let mut raw_events = Vec::new();

        for event in events_arr {
            if !is_in_dc_area(event) {
                continue;
            }

            match parse_event_node(event, artist) {
                Ok(raw_event) => raw_events.push(raw_event),
                Err(e) => {
                    tracing::warn!("Failed to parse Bandsintown event for {}: {}", artist, e);
                }
            }
        }

        Ok(raw_events)
    }
}

#[async_trait]
impl SourceConnector for BandsintownConnector {
    fn source_id(&self) -> &str {
        "bandsintown"
    }

    fn source_type(&self) -> SourceType {
        SourceType::BandsintownApi
    }

    async fn fetch(&self) -> Result<Vec<RawEvent>, IngestionError> {
        let mut all_events = Vec::new();
        let mut any_succeeded = false;

        for artist in &self.seed_artists {
            let encoded_artist = artist.replace(" ", "%20");
            let url = format!("{}/artists/{}/events", self.base_url, encoded_artist);

            match self
                .client
                .get(&url)
                .query(&[("app_id", self.app_id.as_str()), ("date", "upcoming")])
                .send()
                .await
            {
                Ok(response) => match response.text().await {
                    Ok(text) => match Self::parse_json(&text, artist) {
                        Ok(events) => {
                            any_succeeded = true;
                            all_events.extend(events);
                        }
                        Err(e) => {
                            tracing::warn!(
                                "Failed to parse Bandsintown response for {}: {}",
                                artist,
                                e
                            );
                        }
                    },
                    Err(e) => {
                        tracing::warn!("Failed to read response body for {}: {}", artist, e);
                    }
                },
                Err(e) => {
                    tracing::warn!("Failed to fetch Bandsintown events for {}: {}", artist, e);
                }
            }
        }

        if !any_succeeded && all_events.is_empty() {
            return Err(IngestionError::Parse(
                "All Bandsintown artist fetches failed".to_owned(),
            ));
        }

        Ok(all_events)
    }

    fn health_check(&self) -> bool {
        !self.app_id.is_empty() && !self.seed_artists.is_empty()
    }
}

fn parse_bandsintown_datetime(s: &str) -> Result<OffsetDateTime, IngestionError> {
    // Try RFC3339 first (with timezone)
    if let Ok(dt) = OffsetDateTime::parse(s, &time::format_description::well_known::Rfc3339) {
        return Ok(dt);
    }
    // Fall back: no timezone, assume UTC
    // Format: "2026-05-10T23:00:00"
    let fmt = time::macros::format_description!("[year]-[month]-[day]T[hour]:[minute]:[second]");
    time::PrimitiveDateTime::parse(s, fmt)
        .map(|dt| dt.assume_utc())
        .map_err(|_| IngestionError::Parse(format!("Cannot parse datetime: {s}")))
}

fn is_in_dc_area(event: &Value) -> bool {
    let Some(venue) = event.get("venue") else {
        return false;
    };
    let city = venue
        .get("city")
        .and_then(|c| c.as_str())
        .unwrap_or("")
        .to_lowercase();
    let region = venue
        .get("region")
        .and_then(|r| r.as_str())
        .unwrap_or("")
        .to_uppercase();

    city.contains("washington") || region == "DC" || region.contains("DISTRICT OF COLUMBIA")
}

fn parse_event_node(event: &Value, seed_artist: &str) -> Result<RawEvent, IngestionError> {
    let venue = event
        .get("venue")
        .ok_or_else(|| IngestionError::Parse("Missing venue".to_owned()))?;

    let venue_name = venue
        .get("name")
        .and_then(|n| n.as_str())
        .unwrap_or("")
        .to_owned();

    let start_time = parse_bandsintown_datetime(
        event
            .get("datetime")
            .and_then(|dt| dt.as_str())
            .unwrap_or(""),
    )?;

    let lineup = event
        .get("lineup")
        .and_then(|l| l.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|a| a.as_str().map(str::to_owned))
                .collect::<Vec<_>>()
        })
        .unwrap_or_default();

    let title = if !lineup.is_empty() {
        lineup.join(" / ")
    } else {
        seed_artist.to_owned()
    };

    let venue_address = {
        let mut parts = Vec::new();
        if let Some(city) = venue.get("city").and_then(|c| c.as_str()) {
            parts.push(city);
        }
        if let Some(region) = venue.get("region").and_then(|r| r.as_str()) {
            parts.push(region);
        }
        if let Some(country) = venue.get("country").and_then(|c| c.as_str()) {
            parts.push(country);
        }
        if parts.is_empty() {
            None
        } else {
            Some(parts.join(", "))
        }
    };

    let ticket_url = event
        .get("offers")
        .and_then(|o| o.as_array())
        .and_then(|o| o.first())
        .and_then(|o| o.get("url"))
        .and_then(|u| u.as_str())
        .map(str::to_owned);

    let source_url = event.get("url").and_then(|u| u.as_str()).map(str::to_owned);

    let event_id = event
        .get("id")
        .and_then(|i| i.as_str())
        .map(|s| s.to_owned())
        .unwrap_or_else(|| {
            format!(
                "{}:{}:{}",
                seed_artist,
                event
                    .get("datetime")
                    .and_then(|dt| dt.as_str())
                    .unwrap_or(""),
                venue_name
            )
        });

    Ok(RawEvent {
        source_type: SourceType::BandsintownApi,
        source_identifier: Some(format!("{}:{}", seed_artist, event_id)),
        source_url: source_url.clone(),
        title,
        description: None,
        venue_name,
        venue_address,
        artist_names: lineup,
        start_time,
        end_time: None,
        doors_time: None,
        min_price: None,
        max_price: None,
        ticket_url,
        image_url: None,
        age_restriction: None,
        genres: vec![],
        confidence_score: Decimal::new(85, 2),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bandsintown_parses_fixture() {
        let json = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/bandsintown-dc-artists.json"
        ));
        let events = BandsintownConnector::parse_json(json, "test-artist").expect("Parse failed");
        assert!(!events.is_empty(), "Should parse ≥1 event");
        for event in &events {
            assert!(!event.title.trim().is_empty(), "title must not be empty");
            assert!(
                !event.venue_name.trim().is_empty(),
                "venue_name must not be empty"
            );
            assert!(
                event.start_time > OffsetDateTime::UNIX_EPOCH,
                "start_time must be set"
            );
        }
    }
}
