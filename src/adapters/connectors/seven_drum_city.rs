//! 7 Drum City (The Pocket) venue scraper.
// pattern: Imperative Shell

use async_trait::async_trait;
use reqwest::Client;
use rust_decimal::Decimal;
use scraper::{Html, Selector};
use time::OffsetDateTime;

use crate::{
    domain::{error::IngestionError, event::RawEvent, source::SourceType},
    ports::SourceConnector,
};
use super::{generate_source_id, select_text};

const VENUE_NAME: &str = "The Pocket (7 Drum City)";
const VENUE_ADDRESS: &str = "2611 Bladensburg Rd NE, Washington, DC 20018";

pub struct SevenDrumCityScraper {
    client: Client,
}

impl SevenDrumCityScraper {
    pub fn new(client: Client) -> Self {
        Self { client }
    }

    /// Parse HTML document into RawEvents. Used by both fetch() and tests.
    pub fn parse(html: &str) -> Result<Vec<RawEvent>, IngestionError> {
        let document = Html::parse_document(html);

        let container_sel = Selector::parse("div.uui-layout88_item-2.w-dyn-item")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;
        let title_sel = Selector::parse("h3.uui-heading-xxsmall-4")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;
        let month_sel = Selector::parse("div.event-month-2")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;
        let day_sel = Selector::parse("div.event-day-2")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;
        let time_sel = Selector::parse("div.event-time-new-2")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;

        let mut events = Vec::new();
        use chrono::Datelike;
        let current_year = chrono::Utc::now().year() as u32;

        for container in document.select(&container_sel) {
            let title = container
                .select(&title_sel)
                .find(|e| !e.text().collect::<String>().trim().is_empty())
                .map(|e| e.text().collect::<String>().trim().to_owned())
                .unwrap_or_default();

            if title.is_empty() {
                continue;
            }

            let month = select_text(container, &month_sel);
            let day = select_text(container, &day_sel);
            let time_text = select_text(container, &time_sel);

            if month.is_empty() || day.is_empty() {
                continue;
            }

            let date_str = format!("{} {} {}", month, day, current_year);
            let start_time = parse_seven_drum_city_date(&date_str, &time_text)
                .ok_or_else(|| IngestionError::Parse(format!("Cannot parse date: {}", date_str)))?;

            events.push(RawEvent {
                source_type: SourceType::VenueScraper,
                source_identifier: Some(generate_source_id(&title, &date_str)),
                source_url: None,
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
                ticket_url: None,
                image_url: None,
                age_restriction: None,
                genres: vec![],
                confidence_score: Decimal::new(65, 2),
            });
        }

        Ok(events)
    }
}

#[async_trait]
impl SourceConnector for SevenDrumCityScraper {
    fn source_id(&self) -> &str {
        "7-drum-city"
    }

    fn source_type(&self) -> SourceType {
        SourceType::VenueScraper
    }

    async fn fetch(&self) -> Result<Vec<RawEvent>, IngestionError> {
        let url = "https://thepocket.7drumcity.com";
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

        Self::parse(&html)
    }

    fn health_check(&self) -> bool {
        true
    }
}

fn parse_seven_drum_city_date(date_str: &str, time_text: &str) -> Option<OffsetDateTime> {
    let fmt = time::macros::format_description!("[month repr:short] [day] [year]");
    let date = time::Date::parse(date_str, fmt).ok()?;

    let time = if time_text.is_empty() {
        time::Time::from_hms(20, 0, 0).ok()?
    } else {
        // Try to parse time (format: "h:mm a" e.g. "8:00 PM")
        let fmt_time = time::macros::format_description!("[hour repr:12]:[minute] [period]");
        time::Time::parse(time_text, fmt_time)
            .ok()
            .unwrap_or_else(|| time::Time::from_hms(20, 0, 0).unwrap_or(time::Time::MIDNIGHT))
    };

    Some(OffsetDateTime::new_utc(date, time))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn seven_drum_city_parses_fixture() {
        let html = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/7-drum-city-events.html"
        ));
        let events = SevenDrumCityScraper::parse(html).expect("Parse failed");
        assert!(!events.is_empty(), "Should parse ≥1 event");
        let first = &events[0];
        assert!(!first.title.is_empty(), "Title must be non-empty");
        assert_eq!(first.venue_name, "The Pocket (7 Drum City)");
        assert!(first.start_time > OffsetDateTime::UNIX_EPOCH);
    }
}
