//! Pie Shop (Washington DC) two-page venue scraper.

use async_trait::async_trait;
use reqwest::Client;
use rust_decimal::Decimal;
use scraper::{Html, Selector};
use std::str::FromStr;
use time::OffsetDateTime;

use crate::{
    domain::{error::IngestionError, event::RawEvent, source::SourceType},
    ports::SourceConnector,
};

const VENUE_NAME: &str = "Pie Shop";
const VENUE_ADDRESS: &str = "3301 Georgia Ave NW, Washington, DC 20010";
const BASE_URL: &str = "https://www.pieshopdc.com/shows";

pub struct PieShopScraper {
    client: Client,
}

impl PieShopScraper {
    pub fn new(client: Client) -> Self {
        Self { client }
    }

    /// Parse listing HTML into partial RawEvents with detail URLs.
    pub fn parse_listing(html: &str) -> Vec<(RawEvent, String)> {
        let document = Html::parse_document(html);

        let item_sel = match Selector::parse(".ec-col-item.w-dyn-item") {
            Ok(s) => s,
            Err(_) => return vec![],
        };
        let title_sel = match Selector::parse(".title div") {
            Ok(s) => s,
            Err(_) => return vec![],
        };
        let date_sel = match Selector::parse(".start-date div") {
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

            let start_time = match parse_pie_shop_datetime(&date_text) {
                Some(t) => t,
                None => {
                    tracing::warn!(date = %date_text, "Skipping pie shop event: cannot parse date");
                    continue;
                }
            };

            let event = RawEvent {
                source_type: SourceType::VenueScraper,
                source_identifier: Some(generate_source_id(&title, &date_text)),
                source_url: Some(detail_url.clone()),
                title,
                description: None,
                venue_name: VENUE_NAME.to_owned(),
                venue_address: Some(VENUE_ADDRESS.to_owned()),
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
                confidence_score: Decimal::new(72, 2),
            };

            events.push((event, detail_url));
        }

        events
    }

    /// Enrich a partial RawEvent with detail page data.
    pub fn parse_detail(html: &str, event: &mut RawEvent) {
        let document = Html::parse_document(html);

        // Extract price from opendate-widget price attribute
        if let Ok(widget_sel) = Selector::parse("opendate-widget[price]") {
            if let Some(widget_elem) = document.select(&widget_sel).next() {
                if let Some(price_attr) = widget_elem.value().attr("price") {
                    if let Ok(price) = rust_decimal::Decimal::from_str(price_attr) {
                        event.min_price = Some(price);
                        event.max_price = Some(price);
                    }
                }
            }
        }

        // Extract description from .confirm-description
        if let Ok(desc_sel) = Selector::parse(".confirm-description") {
            if let Some(desc_elem) = document.select(&desc_sel).next() {
                let desc = desc_elem.text().collect::<String>().trim().to_owned();
                if !desc.is_empty() {
                    event.description = Some(desc);
                }
            }
        }
    }
}

#[async_trait]
impl SourceConnector for PieShopScraper {
    fn source_id(&self) -> &str {
        "pie-shop"
    }

    fn source_type(&self) -> SourceType {
        SourceType::VenueScraper
    }

    async fn fetch(&self) -> Result<Vec<RawEvent>, IngestionError> {
        let html = self
            .client
            .get(BASE_URL)
            .send()
            .await
            .map_err(|e| IngestionError::Http {
                url: BASE_URL.to_owned(),
                source: e,
            })?
            .text()
            .await
            .map_err(|e| IngestionError::Http {
                url: BASE_URL.to_owned(),
                source: e,
            })?;

        let partial_events = Self::parse_listing(&html);

        let mut events = Vec::new();
        for (mut event, detail_url) in partial_events {
            if !detail_url.is_empty() {
                tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
                match self.client.get(&detail_url).send().await {
                    Ok(resp) => match resp.text().await {
                        Ok(detail_html) => Self::parse_detail(&detail_html, &mut event),
                        Err(e) => {
                            tracing::warn!(error = %e, url = %detail_url, "Failed to read detail page")
                        }
                    },
                    Err(e) => {
                        tracing::warn!(error = %e, url = %detail_url, "Failed to fetch detail page")
                    }
                }
            }
            events.push(event);
        }
        Ok(events)
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

fn parse_pie_shop_datetime(date_text: &str) -> Option<OffsetDateTime> {
    // Try common date formats
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
    fn pie_shop_parses_listing_fixture() {
        let html = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/pie-shop-listing.html"
        ));
        let events = PieShopScraper::parse_listing(html);
        assert!(!events.is_empty(), "Should parse ≥1 event");
    }

    #[test]
    fn pie_shop_empty_fixture_returns_no_events() {
        let html = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/pie-shop-empty.html"
        ));
        let events = PieShopScraper::parse_listing(html);
        assert!(events.is_empty(), "Empty fixture should yield no events");
    }
}
