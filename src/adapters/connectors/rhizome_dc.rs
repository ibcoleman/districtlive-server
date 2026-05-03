//! Rhizome DC (Washington DC) venue scraper.
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

const VENUE_NAME: &str = "Rhizome DC";
const VENUE_ADDRESS: &str = "6950 Maple St NW, Washington, DC 20012";

pub struct RhizomeDcScraper {
    client: Client,
}

impl RhizomeDcScraper {
    pub fn new(client: Client) -> Self {
        Self { client }
    }

    /// Parse HTML document into RawEvents. Used by both fetch() and tests.
    pub fn parse(html: &str) -> Result<Vec<RawEvent>, IngestionError> {
        let document = Html::parse_document(html);

        let event_sel = Selector::parse("article.eventlist-event--upcoming")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;
        let title_sel = Selector::parse("h1.eventlist-title a.eventlist-title-link")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;
        let date_sel = Selector::parse("time.event-date")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;
        let time_sel = Selector::parse("time.event-time-12hr-start")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;

        let mut events = Vec::new();

        for event in document.select(&event_sel) {
            let title = select_text(event, &title_sel);

            if title.is_empty() {
                continue;
            }

            let date_attr = event
                .select(&date_sel)
                .next()
                .and_then(|e| e.value().attr("datetime"))
                .unwrap_or("");

            let time_text = select_text(event, &time_sel);

            let start_time = parse_rhizome_datetime(date_attr, &time_text).ok_or_else(|| {
                IngestionError::Parse(format!(
                    "Cannot parse date/time from {}/{}",
                    date_attr, time_text
                ))
            })?;

            events.push(RawEvent {
                source_type: SourceType::VenueScraper,
                source_identifier: Some(generate_source_id(&title, date_attr)),
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
                confidence_score: Decimal::new(80, 2),
            });
        }

        Ok(events)
    }
}

#[async_trait]
impl SourceConnector for RhizomeDcScraper {
    fn source_id(&self) -> &str {
        "rhizome-dc"
    }

    fn source_type(&self) -> SourceType {
        SourceType::VenueScraper
    }

    async fn fetch(&self) -> Result<Vec<RawEvent>, IngestionError> {
        let url = "https://www.rhizomedc.org/new-events";
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

fn parse_rhizome_datetime(date_attr: &str, time_text: &str) -> Option<OffsetDateTime> {
    use chrono::{Datelike, Timelike};
    // date_attr is typically "yyyy-MM-dd"
    if date_attr.len() < 10 {
        return None;
    }

    let date_str = &date_attr[..10];

    // Try to parse date
    let parsed_date = chrono::NaiveDate::parse_from_str(date_str, "%Y-%m-%d").ok()?;
    let month = time::Month::try_from(parsed_date.month() as u8).ok()?;
    let date =
        time::Date::from_calendar_date(parsed_date.year(), month, parsed_date.day() as u8).ok()?;

    // Try to parse time (format: "h:mm a" e.g. "8:00 PM")
    let time = if time_text.is_empty() {
        time::Time::from_hms(20, 0, 0).ok()?
    } else {
        // Try to parse with chrono: "9:00 PM"
        // First try with uppercase
        if let Ok(parsed_time) = chrono::NaiveTime::parse_from_str(time_text, "%I:%M %p") {
            time::Time::from_hms(parsed_time.hour() as u8, parsed_time.minute() as u8, 0).ok()?
        } else if let Ok(parsed_time) = chrono::NaiveTime::parse_from_str(time_text, "%l:%M %p") {
            // %l is the same as %I but with leading space instead of zero
            time::Time::from_hms(parsed_time.hour() as u8, parsed_time.minute() as u8, 0).ok()?
        } else {
            return None;
        }
    };

    Some(OffsetDateTime::new_utc(date, time))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rhizome_dc_parses_fixture() {
        let html = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/rhizome-dc-events.html"
        ));
        let events = RhizomeDcScraper::parse(html).expect("Parse failed");
        assert!(!events.is_empty(), "Should parse ≥1 event");
        let first = &events[0];
        assert!(!first.title.is_empty(), "Title must be non-empty");
        assert_eq!(first.venue_name, "Rhizome DC");
        assert!(first.start_time > OffsetDateTime::UNIX_EPOCH);
    }
}
