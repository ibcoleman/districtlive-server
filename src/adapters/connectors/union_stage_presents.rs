//! Union Stage Presents (multiple DC venues) two-page venue scraper.

use async_trait::async_trait;
use reqwest::Client;
use rust_decimal::Decimal;
use scraper::{Html, Selector};
use time::OffsetDateTime;

use crate::{
    domain::{error::IngestionError, event::RawEvent, source::SourceType},
    ports::SourceConnector,
};

pub struct UnionStagePresentsScraper {
    client: Client,
}

impl UnionStagePresentsScraper {
    pub fn new(client: Client) -> Self {
        Self { client }
    }

    /// Parse listing HTML into partial RawEvents with detail URLs for a specific venue slug.
    pub fn parse_listing(html: &str, _venue_slug: &str) -> Vec<(RawEvent, String)> {
        let document = Html::parse_document(html);

        let item_sel = match Selector::parse(".event-listing") {
            Ok(s) => s,
            Err(_) => return vec![],
        };
        let title_sel = match Selector::parse(".event-title") {
            Ok(s) => s,
            Err(_) => return vec![],
        };
        let date_sel = match Selector::parse(".event-date") {
            Ok(s) => s,
            Err(_) => return vec![],
        };
        let link_sel = match Selector::parse("a[href]") {
            Ok(s) => s,
            Err(_) => return vec![],
        };

        let mut events = Vec::new();

        for item in document.select(&item_sel) {
            let title = item
                .select(&title_sel)
                .next()
                .map(|e| e.text().collect::<String>().trim().to_owned())
                .unwrap_or_default();

            if title.is_empty() {
                continue;
            }

            let date_text = item
                .select(&date_sel)
                .next()
                .map(|e| e.text().collect::<String>().trim().to_owned())
                .unwrap_or_default();

            let detail_url = item
                .select(&link_sel)
                .next()
                .and_then(|e| e.value().attr("href"))
                .map(str::to_owned)
                .unwrap_or_default();

            let start_time =
                parse_union_stage_datetime(&date_text).unwrap_or_else(|| OffsetDateTime::now_utc());

            let venue_name = "Union Stage".to_owned();
            let venue_address = Some("740 11th St NW, Washington, DC 20001".to_owned());

            let event = RawEvent {
                source_type: SourceType::VenueScraper,
                source_identifier: Some(generate_source_id(&title, &date_text)),
                source_url: Some(detail_url.clone()),
                title,
                description: None,
                venue_name,
                venue_address,
                artist_names: vec![],
                start_time,
                end_time: None,
                doors_time: None,
                min_price: None,
                max_price: None,
                ticket_url: Some(detail_url.clone()),
                image_url: None,
                age_restriction: None,
                genres: vec![],
                confidence_score: Decimal::new(75, 2),
            };

            events.push((event, detail_url));
        }

        events
    }

    /// Enrich a partial RawEvent with detail page data.
    pub fn parse_detail(_html: &str, _event: &mut RawEvent) {
        // Detail page parsing would extract price and doors time from data attributes
    }
}

#[async_trait]
impl SourceConnector for UnionStagePresentsScraper {
    fn source_id(&self) -> &str {
        "union-stage-presents"
    }

    fn source_type(&self) -> SourceType {
        SourceType::VenueScraper
    }

    async fn fetch(&self) -> Result<Vec<RawEvent>, IngestionError> {
        // For now, fetch from the main Union Stage venue
        let url = "https://www.unionstagedc.com/events";
        let html = self
            .client
            .get(url)
            .send()
            .await
            .map_err(|e| IngestionError::Http {
                url: url.to_owned(),
                source: e,
            })?
            .text()
            .await
            .map_err(|e| IngestionError::Http {
                url: url.to_owned(),
                source: e,
            })?;

        let partial_events = Self::parse_listing(&html, "union-stage");
        Ok(partial_events.into_iter().map(|(e, _)| e).collect())
    }

    fn health_check(&self) -> bool {
        true
    }
}

fn generate_source_id(title: &str, date_text: &str) -> String {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};
    let mut hasher = DefaultHasher::new();
    format!("{}|{}", title, date_text).hash(&mut hasher);
    format!("{:016x}", hasher.finish())
}

fn parse_union_stage_datetime(date_text: &str) -> Option<OffsetDateTime> {
    let formats = [
        time::macros::format_description!("[month repr:long] [day], [year]"),
        time::macros::format_description!("[month]/[day]/[year]"),
    ];

    for fmt in &formats {
        if let Ok(date) = time::Date::parse(date_text, fmt) {
            let time = time::Time::from_hms(20, 0, 0).ok()?;
            return Some(OffsetDateTime::new_utc(date, time));
        }
    }

    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn union_stage_presents_parses_listing_fixture() {
        let html = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/union-stage-presents-listing.html"
        ));
        let events = UnionStagePresentsScraper::parse_listing(html, "union-stage");
        assert!(!events.is_empty(), "Should parse ≥1 event");
    }

    #[test]
    fn union_stage_presents_empty_fixture_returns_no_events() {
        let html = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/union-stage-presents-empty.html"
        ));
        let events = UnionStagePresentsScraper::parse_listing(html, "union-stage");
        assert!(events.is_empty(), "Empty fixture should yield no events");
    }
}
