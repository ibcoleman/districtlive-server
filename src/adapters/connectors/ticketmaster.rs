//! Ticketmaster Discovery API connector for DC music events.

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

pub struct TicketmasterConnector {
    client: Client,
    api_key: String,
    base_url: String,
}

impl TicketmasterConnector {
    pub fn new(client: Client, config: &Config) -> Option<Self> {
        config.ticketmaster_api_key.as_ref().map(|key| Self {
            client,
            api_key: key.clone(),
            base_url: "https://app.ticketmaster.com/discovery/v2".to_owned(),
        })
    }

    /// Parse JSON response into RawEvents. Used by both fetch() and tests.
    pub fn parse_json(json_str: &str) -> Result<Vec<RawEvent>, IngestionError> {
        let root: Value = serde_json::from_str(json_str)
            .map_err(|e| IngestionError::Parse(format!("Invalid JSON: {}", e)))?;

        let empty_vec = vec![];
        let events_arr = root
            .get("_embedded")
            .and_then(|e| e.get("events"))
            .and_then(|e| e.as_array())
            .unwrap_or(&empty_vec);

        let mut raw_events = Vec::new();

        for event in events_arr {
            if !is_dc_event(event) {
                continue;
            }

            match parse_event_node(event) {
                Ok(raw_event) => raw_events.push(raw_event),
                Err(e) => {
                    tracing::warn!("Failed to parse Ticketmaster event: {}", e);
                }
            }
        }

        Ok(raw_events)
    }
}

#[async_trait]
impl SourceConnector for TicketmasterConnector {
    fn source_id(&self) -> &str {
        "ticketmaster"
    }

    fn source_type(&self) -> SourceType {
        SourceType::TicketmasterApi
    }

    async fn fetch(&self) -> Result<Vec<RawEvent>, IngestionError> {
        let url = format!("{}/events.json", self.base_url);
        let response = self
            .client
            .get(&url)
            .query(&[
                ("apikey", self.api_key.as_str()),
                ("classificationName", "music"),
                ("city", "Washington"),
                ("stateCode", "DC"),
                ("countryCode", "US"),
                ("size", "200"),
                ("sort", "date,asc"),
            ])
            .send()
            .await
            .map_err(|e| IngestionError::Http {
                url: url.clone(),
                source: e,
            })?
            .text()
            .await
            .map_err(|e| IngestionError::Http {
                url: url.clone(),
                source: e,
            })?;

        Self::parse_json(&response)
    }

    fn health_check(&self) -> bool {
        !self.api_key.is_empty()
    }
}

fn is_dc_event(event: &Value) -> bool {
    let venue = event
        .get("_embedded")
        .and_then(|e| e.get("venues"))
        .and_then(|v| v.as_array())
        .and_then(|v| v.first());

    if venue.is_none() {
        return false;
    }

    let venue = venue.unwrap();
    let city = venue
        .get("city")
        .and_then(|c| c.get("name"))
        .and_then(|n| n.as_str())
        .unwrap_or("");
    let state = venue
        .get("state")
        .and_then(|s| s.get("stateCode"))
        .and_then(|s| s.as_str())
        .unwrap_or("");

    city.eq_ignore_ascii_case("Washington") && state.eq_ignore_ascii_case("DC")
}

fn parse_event_node(event: &Value) -> Result<RawEvent, IngestionError> {
    let title = event
        .get("name")
        .and_then(|n| n.as_str())
        .unwrap_or("")
        .to_owned();

    if title.is_empty() {
        return Err(IngestionError::Parse("Missing or empty title".to_owned()));
    }

    let venue = event
        .get("_embedded")
        .and_then(|e| e.get("venues"))
        .and_then(|v| v.as_array())
        .and_then(|v| v.first());

    let venue_name = venue
        .and_then(|v| v.get("name"))
        .and_then(|n| n.as_str())
        .unwrap_or("")
        .to_owned();

    let venue_address = venue.and_then(|v| {
        let mut parts = Vec::new();
        if let Some(addr) = v
            .get("address")
            .and_then(|a| a.get("line1"))
            .and_then(|l| l.as_str())
        {
            parts.push(addr);
        }
        if let Some(addr) = v
            .get("address")
            .and_then(|a| a.get("line2"))
            .and_then(|l| l.as_str())
        {
            parts.push(addr);
        }
        if let Some(city) = v
            .get("city")
            .and_then(|c| c.get("name"))
            .and_then(|n| n.as_str())
        {
            parts.push(city);
        }
        if let Some(state) = v
            .get("state")
            .and_then(|s| s.get("stateCode"))
            .and_then(|s| s.as_str())
        {
            parts.push(state);
        }
        if let Some(zip) = v.get("postalCode").and_then(|z| z.as_str()) {
            parts.push(zip);
        }
        if parts.is_empty() {
            None
        } else {
            Some(parts.join(", "))
        }
    });

    let start_time = event
        .get("dates")
        .and_then(|d| d.get("start"))
        .and_then(|s| s.get("dateTime").or_else(|| s.get("localDate")))
        .and_then(|t| t.as_str())
        .and_then(parse_time)
        .ok_or_else(|| IngestionError::Parse("Missing or unparseable startTime".to_owned()))?;

    let artists = event
        .get("_embedded")
        .and_then(|e| e.get("attractions"))
        .and_then(|a| a.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|a| a.get("name").and_then(|n| n.as_str()).map(str::to_owned))
                .collect::<Vec<_>>()
        })
        .unwrap_or_default();

    let min_price = event
        .get("priceRanges")
        .and_then(|p| p.as_array())
        .and_then(|p| p.first())
        .and_then(|p| p.get("min"))
        .and_then(|m| m.as_f64())
        .and_then(|f| Decimal::try_from(f).ok());

    let max_price = event
        .get("priceRanges")
        .and_then(|p| p.as_array())
        .and_then(|p| p.first())
        .and_then(|p| p.get("max"))
        .and_then(|m| m.as_f64())
        .and_then(|f| Decimal::try_from(f).ok());

    let source_url = event.get("url").and_then(|u| u.as_str()).map(str::to_owned);

    Ok(RawEvent {
        source_type: SourceType::TicketmasterApi,
        source_identifier: event.get("id").and_then(|i| i.as_str()).map(str::to_owned),
        source_url: source_url.clone(),
        title,
        description: None,
        venue_name,
        venue_address,
        artist_names: artists,
        start_time,
        end_time: None,
        doors_time: None,
        min_price,
        max_price,
        ticket_url: source_url,
        image_url: event
            .get("images")
            .and_then(|i| i.as_array())
            .and_then(|a| a.first())
            .and_then(|i| i.get("url"))
            .and_then(|u| u.as_str())
            .map(str::to_owned),
        age_restriction: None,
        genres: vec![],
        confidence_score: Decimal::new(90, 2),
    })
}

fn parse_time(s: &str) -> Option<OffsetDateTime> {
    OffsetDateTime::parse(s, &time::format_description::well_known::Rfc3339).ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ticketmaster_parses_fixture() {
        let json = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/ticketmaster-dc-events.json"
        ));
        let events = TicketmasterConnector::parse_json(json).expect("Parse failed");
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
