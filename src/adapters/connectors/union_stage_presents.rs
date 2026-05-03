//! Union Stage Presents (multiple DC venues) two-page venue scraper.
// pattern: Imperative Shell

use async_trait::async_trait;
use reqwest::Client;
use rust_decimal::Decimal;
use scraper::{Html, Selector};
use std::str::FromStr;
use time::OffsetDateTime;

use super::{generate_source_id, select_text};
use crate::{
    domain::{error::IngestionError, event::RawEvent, source::SourceType},
    ports::SourceConnector,
};

fn confidence_score() -> Decimal {
    Decimal::new(75, 2)
}

// All 7 Union Stage Presents venues: slug -> (name, address)
const VENUE_INFO: &[(&str, &str, &str)] = &[
    (
        "union-stage",
        "Union Stage",
        "740 Water St SW, Washington, DC 20024",
    ),
    (
        "jammin-java",
        "Jammin Java",
        "227 Maple Ave E, Vienna, VA 22180",
    ),
    (
        "pearl-street-warehouse",
        "Pearl Street Warehouse",
        "33 Pearl St SW, Washington, DC 20024",
    ),
    (
        "howard-theatre",
        "The Howard Theatre",
        "620 T St NW, Washington, DC 20001",
    ),
    (
        "miracle-theatre",
        "Miracle Theatre",
        "535 8th St SE, Washington, DC 20003",
    ),
    (
        "capital-turnaround",
        "Capital Turnaround",
        "70 N St SE, Washington, DC 20003",
    ),
    (
        "nationals-park",
        "Nationals Park",
        "1500 S Capitol St SE, Washington, DC 20003",
    ),
];

pub struct UnionStagePresentsScraper {
    client: Client,
}

impl UnionStagePresentsScraper {
    pub fn new(client: Client) -> Self {
        Self { client }
    }

    /// Parse listing HTML into partial RawEvents with detail URLs for a specific venue slug.
    pub fn parse_listing(
        html: &str,
        venue_slug: &str,
        venue_name: &str,
        venue_address: &str,
    ) -> Vec<(RawEvent, String)> {
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
            let title = select_text(item, &title_sel);

            if title.is_empty() {
                continue;
            }

            let date_text = select_text(item, &date_sel);

            let detail_url = item
                .select(&link_sel)
                .next()
                .and_then(|e| e.value().attr("href"))
                .map(str::to_owned)
                .unwrap_or_default();

            let start_time = match parse_union_stage_datetime(&date_text) {
                Some(t) => t,
                None => {
                    tracing::warn!(
                        date = %date_text,
                        venue = %venue_slug,
                        "Skipping union stage event: cannot parse date"
                    );
                    continue;
                }
            };

            let event = RawEvent {
                source_type: SourceType::VenueScraper,
                source_identifier: Some(generate_source_id(&title, &date_text)),
                source_url: Some(detail_url.clone()),
                title,
                description: None,
                venue_name: venue_name.to_owned(),
                venue_address: Some(venue_address.to_owned()),
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
                confidence_score: confidence_score(),
            };

            events.push((event, detail_url));
        }

        events
    }

    /// Enrich a partial RawEvent with detail page data.
    pub fn parse_detail(html: &str, event: &mut RawEvent) {
        let document = Html::parse_document(html);

        // Extract description from about section
        if let Ok(desc_sel) = Selector::parse(".about-copy") {
            if let Some(desc_elem) = document.select(&desc_sel).next() {
                let desc = desc_elem.text().collect::<String>().trim().to_owned();
                if !desc.is_empty() {
                    event.description = Some(desc);
                }
            }
        }

        // Try to extract price from data attributes or price display
        // Look for data-price attribute or price text
        if let Ok(price_sel) = Selector::parse("[data-price]") {
            if let Some(price_elem) = document.select(&price_sel).next() {
                if let Some(price_attr) = price_elem.value().attr("data-price") {
                    if let Ok(price) = Decimal::from_str(price_attr) {
                        event.min_price = Some(price);
                    }
                }
            }
        }

        // Try to extract doors time from data attributes
        if let Ok(doors_sel) = Selector::parse("[data-doors]") {
            if let Some(doors_elem) = document.select(&doors_sel).next() {
                if let Some(doors_attr) = doors_elem.value().attr("data-doors") {
                    // Try to parse as ISO instant
                    if let Ok(dt) = OffsetDateTime::parse(
                        doors_attr,
                        &time::format_description::well_known::Rfc3339,
                    ) {
                        event.doors_time = Some(dt);
                    }
                }
            }
        }
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
        let mut all_events = Vec::new();

        // Fetch from all 7 venues
        for (slug, name, address) in VENUE_INFO {
            let url = format!("https://www.unionstagepresents.com/{}", slug);
            match self.client.get(&url).send().await {
                Ok(response) => match response.text().await {
                    Ok(html) => {
                        let partial_events = Self::parse_listing(&html, slug, name, address);
                        for (mut event, detail_url) in partial_events {
                            if !detail_url.is_empty() {
                                tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
                                match self.client.get(&detail_url).send().await {
                                    Ok(resp) => match resp.text().await {
                                        Ok(detail_html) => {
                                            Self::parse_detail(&detail_html, &mut event)
                                        }
                                        Err(e) => {
                                            tracing::warn!(
                                                error = %e,
                                                url = %detail_url,
                                                "Failed to read detail page"
                                            )
                                        }
                                    },
                                    Err(e) => {
                                        tracing::warn!(
                                            error = %e,
                                            url = %detail_url,
                                            "Failed to fetch detail page"
                                        )
                                    }
                                }
                            }
                            all_events.push(event);
                        }
                    }
                    Err(e) => {
                        tracing::warn!(
                            error = %e,
                            venue = %slug,
                            "Failed to read response body for venue"
                        );
                    }
                },
                Err(e) => {
                    tracing::warn!(
                        error = %e,
                        venue = %slug,
                        "Failed to fetch events for venue"
                    );
                }
            }
        }

        Ok(all_events)
    }

    fn health_check(&self) -> bool {
        true
    }
}

fn parse_union_stage_datetime(date_text: &str) -> Option<OffsetDateTime> {
    let formats = [
        time::macros::format_description!("[month repr:long] [day], [year]"),
        time::macros::format_description!("[month]/[day]/[year]"),
    ];

    for fmt in &formats {
        if let Ok(date) = time::Date::parse(date_text, fmt) {
            let time = time::Time::from_hms(20, 0, 0).unwrap_or(time::Time::MIDNIGHT);
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
        let events = UnionStagePresentsScraper::parse_listing(
            html,
            "union-stage",
            "Union Stage",
            "740 Water St SW, Washington, DC 20024",
        );
        assert!(!events.is_empty(), "Should parse ≥1 event");
    }

    #[test]
    fn union_stage_presents_empty_fixture_returns_no_events() {
        let html = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/union-stage-presents-empty.html"
        ));
        let events = UnionStagePresentsScraper::parse_listing(
            html,
            "union-stage",
            "Union Stage",
            "740 Water St SW, Washington, DC 20024",
        );
        assert!(events.is_empty(), "Empty fixture should yield no events");
    }
}
