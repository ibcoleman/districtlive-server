//! Dice.fm HTML connector with JSON-LD event extraction.

use async_trait::async_trait;
use reqwest::Client;
use rust_decimal::Decimal;
use scraper::{Html, Selector};
use serde_json::Value;
use time::OffsetDateTime;

use crate::{
    domain::{error::IngestionError, event::RawEvent, source::SourceType},
    ports::SourceConnector,
};

pub struct DiceFmConnector {
    #[allow(dead_code)]
    client: Client,
}

impl DiceFmConnector {
    pub fn new(client: Client) -> Self {
        Self { client }
    }

    /// Parse HTML with JSON-LD blocks into RawEvents. Used by both fetch() and tests.
    pub fn parse_html(html: &str, _venue_slug: &str) -> Result<Vec<RawEvent>, IngestionError> {
        let document = Html::parse_document(html);

        // Find script[type="application/ld+json"] tags
        let script_selector = Selector::parse(r#"script[type="application/ld+json"]"#)
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;

        let mut events = Vec::new();

        for script in document.select(&script_selector) {
            let json_text: String = script.text().collect::<String>().trim().to_owned();
            if json_text.is_empty() {
                continue;
            }

            match serde_json::from_str::<Value>(&json_text) {
                Ok(val) => {
                    // Look for @type == "Place" objects with nested events
                    if val.get("@type").and_then(|t| t.as_str()) == Some("Place") {
                        match parse_place_node(&val) {
                            Ok(mut place_events) => {
                                events.append(&mut place_events);
                            }
                            Err(e) => {
                                tracing::warn!("Failed to parse Place node: {}", e);
                            }
                        }
                    }
                }
                Err(e) => {
                    tracing::warn!("Failed to parse JSON-LD block: {}", e);
                }
            }
        }

        Ok(events)
    }
}

#[async_trait]
impl SourceConnector for DiceFmConnector {
    fn source_id(&self) -> &str {
        "dicefm"
    }

    fn source_type(&self) -> SourceType {
        SourceType::DiceFm
    }

    async fn fetch(&self) -> Result<Vec<RawEvent>, IngestionError> {
        // Dice.fm requires multiple venue requests. For now, we'll return empty.
        // In full implementation, iterate over configured venue slugs.
        Ok(vec![])
    }

    fn health_check(&self) -> bool {
        true
    }
}

fn parse_place_node(place: &Value) -> Result<Vec<RawEvent>, IngestionError> {
    let venue_name = place
        .get("name")
        .and_then(|n| n.as_str())
        .map(str::to_owned);

    let venue_address = extract_address(place.get("address"));

    let empty_vec = vec![];
    let events_arr = place
        .get("event")
        .and_then(|e| e.as_array())
        .unwrap_or(&empty_vec);

    let mut events = Vec::new();

    for event_val in events_arr {
        match parse_music_event(event_val, venue_name.as_deref(), venue_address.as_deref()) {
            Ok(Some(event)) => events.push(event),
            Ok(None) => {
                tracing::debug!("Skipping event with missing required fields");
            }
            Err(e) => {
                tracing::warn!("Failed to parse MusicEvent: {}", e);
            }
        }
    }

    Ok(events)
}

fn parse_music_event(
    event: &Value,
    parent_venue_name: Option<&str>,
    parent_venue_address: Option<&str>,
) -> Result<Option<RawEvent>, IngestionError> {
    let title = event.get("name").and_then(|n| n.as_str()).and_then(|n| {
        if n.is_empty() {
            None
        } else {
            Some(n.to_owned())
        }
    });

    if title.is_none() {
        return Ok(None);
    }

    let title = title.unwrap();

    let url = event.get("url").and_then(|u| u.as_str()).map(str::to_owned);

    let start_time = event
        .get("startDate")
        .and_then(|sd| sd.as_str())
        .and_then(parse_iso_instant);

    let end_time = event
        .get("endDate")
        .and_then(|ed| ed.as_str())
        .and_then(parse_iso_instant);

    let description = event
        .get("description")
        .and_then(|d| d.as_str())
        .and_then(|d| {
            if d.is_empty() {
                None
            } else {
                Some(d.to_owned())
            }
        });

    let image_url = extract_first_image(event.get("image"));

    let (min_price, max_price) = extract_pricing(event.get("offers"));

    // Event's own location overrides parent Place
    let location = event.get("location");
    let event_venue_name = location
        .and_then(|l| l.get("name"))
        .and_then(|n| n.as_str())
        .and_then(|n| {
            if n.is_empty() {
                None
            } else {
                Some(n.to_owned())
            }
        });

    let venue_name = event_venue_name.or_else(|| parent_venue_name.map(str::to_owned));

    let event_venue_address = location.and_then(|l| extract_address(l.get("address")));

    let venue_address = event_venue_address.or_else(|| parent_venue_address.map(str::to_owned));

    let source_identifier = url
        .as_ref()
        .map(|u| derive_source_identifier(u))
        .or_else(|| {
            Some(derive_source_identifier(&format!(
                "{}|{}",
                title,
                event
                    .get("startDate")
                    .and_then(|sd| sd.as_str())
                    .unwrap_or("")
            )))
        });

    Ok(Some(RawEvent {
        source_type: SourceType::DiceFm,
        source_identifier,
        source_url: url.clone(),
        title,
        description,
        venue_name: venue_name.unwrap_or_default(),
        venue_address,
        artist_names: vec![],
        start_time: start_time
            .ok_or_else(|| IngestionError::Parse("Missing startDate".to_owned()))?,
        end_time,
        doors_time: None,
        min_price,
        max_price,
        ticket_url: url,
        image_url,
        age_restriction: None,
        genres: vec![],
        confidence_score: Decimal::new(80, 2),
    }))
}

fn extract_address(address: Option<&Value>) -> Option<String> {
    match address {
        None => None,
        Some(addr) if addr.is_null() => None,
        Some(addr) if addr.is_string() => addr.as_str().and_then(|s| {
            if s.is_empty() {
                None
            } else {
                Some(s.to_owned())
            }
        }),
        Some(addr) if addr.is_object() => {
            let parts = vec![
                addr.get("streetAddress")
                    .and_then(|s| s.as_str())
                    .unwrap_or(""),
                addr.get("addressLocality")
                    .and_then(|s| s.as_str())
                    .unwrap_or(""),
                addr.get("addressRegion")
                    .and_then(|s| s.as_str())
                    .unwrap_or(""),
                addr.get("postalCode")
                    .and_then(|s| s.as_str())
                    .unwrap_or(""),
            ];
            let filtered: Vec<_> = parts.into_iter().filter(|s| !s.is_empty()).collect();
            if filtered.is_empty() {
                None
            } else {
                Some(filtered.join(", "))
            }
        }
        _ => None,
    }
}

fn extract_first_image(image: Option<&Value>) -> Option<String> {
    match image {
        None => None,
        Some(img) if img.is_null() => None,
        Some(img) if img.is_array() => {
            img.as_array()
                .and_then(|arr| arr.first())
                .and_then(|first| {
                    if first.is_string() {
                        first.as_str().map(str::to_owned)
                    } else {
                        first.get("url").and_then(|u| u.as_str()).map(str::to_owned)
                    }
                })
        }
        Some(img) if img.is_string() => img.as_str().map(str::to_owned),
        Some(img) if img.is_object() => img.get("url").and_then(|u| u.as_str()).map(str::to_owned),
        _ => None,
    }
}

fn extract_pricing(offers: Option<&Value>) -> (Option<Decimal>, Option<Decimal>) {
    use std::str::FromStr;

    match offers {
        None => (None, None),
        Some(off) if off.is_null() => (None, None),
        Some(off) if !off.is_array() => (None, None),
        Some(off) => {
            let prices: Vec<Decimal> = off
                .as_array()
                .unwrap_or(&vec![])
                .iter()
                .filter_map(|o| o.get("price"))
                .filter_map(|p| p.as_str())
                .filter_map(|s| Decimal::from_str(s).ok())
                .filter(|d| d > &Decimal::ZERO)
                .collect();

            if prices.is_empty() {
                (None, None)
            } else {
                let min = prices.iter().min().cloned();
                let max = prices.iter().max().cloned();
                (min, max)
            }
        }
    }
}

fn parse_iso_instant(date_str: &str) -> Option<OffsetDateTime> {
    OffsetDateTime::parse(date_str, &time::format_description::well_known::Rfc3339)
        .ok()
        .or_else(|| {
            // Try ISO 8601 Instant format
            time::OffsetDateTime::parse(
                date_str,
                &time::format_description::well_known::Iso8601::DEFAULT,
            )
            .ok()
        })
}

fn derive_source_identifier(input: &str) -> String {
    let extracted = input.split("dice.fm/").nth(1).unwrap_or(input);
    if extracted.is_empty() {
        use std::collections::hash_map::DefaultHasher;
        use std::hash::{Hash, Hasher};
        let mut hasher = DefaultHasher::new();
        input.hash(&mut hasher);
        format!("{:016x}", hasher.finish())
    } else {
        extracted.to_owned()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn dicefm_parses_fixture_with_events() {
        let html = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/dicefm-venue-events.html"
        ));
        let events = DiceFmConnector::parse_html(html, "test-venue").expect("Parse failed");
        assert!(!events.is_empty(), "Should parse ≥1 event");
        for event in &events {
            assert!(!event.title.trim().is_empty(), "title must not be empty");
            assert!(
                !event.venue_name.trim().is_empty(),
                "venue_name must not be empty"
            );
        }
    }

    #[test]
    fn dicefm_empty_fixture_returns_no_events() {
        let html = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/dicefm-empty-events.html"
        ));
        let events = DiceFmConnector::parse_html(html, "test-venue").expect("Parse failed");
        assert!(events.is_empty(), "Empty fixture should yield no events");
    }
}
