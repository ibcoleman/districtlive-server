//! Black Cat (Washington DC) venue scraper.

use async_trait::async_trait;
use chrono::Datelike;
use reqwest::Client;
use rust_decimal::Decimal;
use scraper::{Html, Selector};
use time::OffsetDateTime;

use crate::{
    domain::{error::IngestionError, event::RawEvent, source::SourceType},
    ports::SourceConnector,
};

const VENUE_NAME: &str = "Black Cat";
const VENUE_ADDRESS: &str = "1811 14th St NW, Washington, DC 20009";

pub struct BlackCatScraper {
    client: Client,
}

impl BlackCatScraper {
    pub fn new(client: Client) -> Self {
        Self { client }
    }

    /// Parse HTML document into RawEvents. Used by both fetch() and tests.
    pub fn parse(html: &str) -> Result<Vec<RawEvent>, IngestionError> {
        let document = Html::parse_document(html);

        let show_sel = Selector::parse("div.show")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;
        let title_sel = Selector::parse("h1.headline a")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;
        let date_sel = Selector::parse("h2.date")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;

        let mut events = Vec::new();
        let current_year = chrono::Utc::now().format("%Y").to_string();

        for show in document.select(&show_sel) {
            let title = show
                .select(&title_sel)
                .next()
                .map(|e| e.text().collect::<String>().trim().to_owned())
                .unwrap_or_default();

            if title.is_empty() {
                continue;
            }

            let date_text = show
                .select(&date_sel)
                .next()
                .map(|e| e.text().collect::<String>().trim().to_owned())
                .unwrap_or_default();

            let date_with_year = format!("{} {}", date_text, current_year);
            let start_time = parse_black_cat_date(&date_with_year).ok_or_else(|| {
                IngestionError::Parse(format!("Cannot parse date: {}", date_text))
            })?;

            let ticket_url = Selector::parse("div.show-details > a[href*='etix.com']")
                .ok()
                .and_then(|sel| {
                    show.select(&sel)
                        .next()
                        .and_then(|a| a.value().attr("href"))
                        .map(str::to_owned)
                });

            events.push(RawEvent {
                source_type: SourceType::VenueScraper,
                source_identifier: Some(generate_source_id(&title, &date_text)),
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
                ticket_url,
                image_url: None,
                age_restriction: None,
                genres: vec![],
                confidence_score: Decimal::new(70, 2),
            });
        }

        Ok(events)
    }
}

#[async_trait]
impl SourceConnector for BlackCatScraper {
    fn source_id(&self) -> &str {
        "black-cat"
    }

    fn source_type(&self) -> SourceType {
        SourceType::VenueScraper
    }

    async fn fetch(&self) -> Result<Vec<RawEvent>, IngestionError> {
        let url = "https://www.blackcatdc.com/schedule.html";
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

fn generate_source_id(title: &str, date_text: &str) -> String {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};
    let mut hasher = DefaultHasher::new();
    format!("{}|{}", title, date_text).hash(&mut hasher);
    format!("{:016x}", hasher.finish())
}

fn parse_black_cat_date(s: &str) -> Option<OffsetDateTime> {
    let trimmed = s.trim();
    let parts: Vec<&str> = trimmed.split_whitespace().collect();

    if parts.is_empty() {
        return None;
    }

    // Get current year
    let current_year = chrono::Utc::now().year();

    // Format examples: "Friday March 6", "Saturday February 21"
    let with_year = if parts.last().and_then(|p| p.parse::<u32>().ok()).is_some() {
        // Already has year
        trimmed.to_string()
    } else {
        // Append year
        format!("{} {}", trimmed, current_year)
    };

    // Try parsing with chrono
    if let Ok(parsed) = chrono::NaiveDate::parse_from_str(&with_year, "%A %B %d %Y") {
        // "Friday March 6 2026"
        let month = time::Month::try_from(parsed.month() as u8).ok()?;
        let date = time::Date::from_calendar_date(parsed.year(), month, parsed.day() as u8).ok()?;
        let time = time::Time::from_hms(20, 0, 0).ok()?;
        return Some(OffsetDateTime::new_utc(date, time));
    }

    if let Ok(parsed) = chrono::NaiveDate::parse_from_str(&with_year, "%B %d %Y") {
        // "March 6 2026"
        let month = time::Month::try_from(parsed.month() as u8).ok()?;
        let date = time::Date::from_calendar_date(parsed.year(), month, parsed.day() as u8).ok()?;
        let time = time::Time::from_hms(20, 0, 0).ok()?;
        return Some(OffsetDateTime::new_utc(date, time));
    }

    if let Ok(parsed) = chrono::NaiveDate::parse_from_str(&with_year, "%A %b %d %Y") {
        // "Friday Mar 6 2026"
        let month = time::Month::try_from(parsed.month() as u8).ok()?;
        let date = time::Date::from_calendar_date(parsed.year(), month, parsed.day() as u8).ok()?;
        let time = time::Time::from_hms(20, 0, 0).ok()?;
        return Some(OffsetDateTime::new_utc(date, time));
    }

    if let Ok(parsed) = chrono::NaiveDate::parse_from_str(&with_year, "%b %d %Y") {
        // "Mar 6 2026"
        let month = time::Month::try_from(parsed.month() as u8).ok()?;
        let date = time::Date::from_calendar_date(parsed.year(), month, parsed.day() as u8).ok()?;
        let time = time::Time::from_hms(20, 0, 0).ok()?;
        return Some(OffsetDateTime::new_utc(date, time));
    }

    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn black_cat_parses_fixture() {
        let html = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/black-cat-schedule.html"
        ));
        let events = BlackCatScraper::parse(html).expect("Parse failed");
        assert!(!events.is_empty(), "Should parse ≥1 event");
        let first = &events[0];
        assert!(!first.title.is_empty(), "Title must be non-empty");
        assert_eq!(first.venue_name, "Black Cat");
        assert!(first.start_time > OffsetDateTime::UNIX_EPOCH);
    }
}
