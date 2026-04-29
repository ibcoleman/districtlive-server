//! DC9 (Washington DC) venue scraper.

use async_trait::async_trait;
use reqwest::Client;
use rust_decimal::Decimal;
use scraper::{Html, Selector};
use time::{Date, OffsetDateTime, Time};

use crate::{
    domain::{error::IngestionError, event::RawEvent, source::SourceType},
    ports::SourceConnector,
};

const VENUE_NAME: &str = "DC9";
const VENUE_ADDRESS: &str = "1940 9th St NW, Washington, DC 20001";

pub struct Dc9Scraper {
    client: Client,
}

impl Dc9Scraper {
    pub fn new(client: Client) -> Self {
        Self { client }
    }

    /// Parse HTML document into RawEvents. Used by both fetch() and tests.
    pub fn parse(html: &str) -> Result<Vec<RawEvent>, IngestionError> {
        let document = Html::parse_document(html);

        let listing_sel = Selector::parse("div.listing.plotCard[data-listing-id]")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;
        let title_sel = Selector::parse("div.listing__title h3")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;
        let date_sel = Selector::parse("div.listingDateTime span")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;
        let doors_sel = Selector::parse("p.listing-doors")
            .map_err(|_| IngestionError::Parse("Invalid selector".to_owned()))?;

        let mut events = Vec::new();
        use chrono::Datelike;
        let current_year = chrono::Utc::now().year() as u32;

        for listing in document.select(&listing_sel) {
            let title = listing
                .select(&title_sel)
                .next()
                .map(|e| e.text().collect::<String>().trim().to_owned())
                .unwrap_or_default();

            if title.is_empty() {
                continue;
            }

            let date_text = listing
                .select(&date_sel)
                .next()
                .map(|e| e.text().collect::<String>().trim().to_owned())
                .unwrap_or_default();

            if date_text.is_empty() {
                continue;
            }

            let doors_text = listing
                .select(&doors_sel)
                .next()
                .map(|e| e.text().collect::<String>().trim().to_owned())
                .unwrap_or_default();

            let event_date = parse_dc9_date(&date_text, current_year);
            let doors_time = parse_time_from_doors(&doors_text, "Doors");
            let show_time = parse_time_from_doors(&doors_text, "Show");

            let start_time =
                resolve_datetime(event_date, show_time.or(doors_time)).ok_or_else(|| {
                    IngestionError::Parse(format!("Cannot parse date: {}", date_text))
                })?;

            let doors_instant = if doors_time.is_some() && doors_time != show_time {
                resolve_datetime(event_date, doors_time)
            } else {
                None
            };

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
                doors_time: doors_instant,
                min_price: None,
                max_price: None,
                ticket_url: None,
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
impl SourceConnector for Dc9Scraper {
    fn source_id(&self) -> &str {
        "dc9"
    }

    fn source_type(&self) -> SourceType {
        SourceType::VenueScraper
    }

    async fn fetch(&self) -> Result<Vec<RawEvent>, IngestionError> {
        let url = "https://dc9.club/";
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

fn parse_dc9_date(date_text: &str, current_year: u32) -> Option<Date> {
    if date_text.is_empty() {
        return None;
    }

    let with_year = format!("{} {}", date_text, current_year);
    let fmt =
        time::macros::format_description!("[weekday repr:short], [month repr:short] [day] [year]");

    time::Date::parse(&with_year, fmt).ok().map(|mut parsed| {
        // If date is >2 months in the past, assume next year
        let now = time::OffsetDateTime::now_utc().date();
        let two_months_ago = now.saturating_sub(time::Duration::days(60));
        if parsed < two_months_ago {
            parsed = parsed.saturating_add(time::Duration::days(365));
        }
        parsed
    })
}

fn parse_time_from_doors(doors_text: &str, label: &str) -> Option<Time> {
    if doors_text.is_empty() {
        return None;
    }

    let label_index = doors_text.to_lowercase().find(&label.to_lowercase())?;
    let after_label = &doors_text[label_index + label.len()..];

    // Regex pattern: (\d{1,2}(?::\d{2})?)(am|pm)
    let parts: Vec<&str> = after_label
        .split(|c: char| !c.is_alphanumeric() && c != ':')
        .collect();
    let mut found_time = false;
    let mut hour_str = "";
    let mut am_pm = "";

    for part in parts {
        if part.contains(':') || (part.len() <= 2 && part.chars().all(|c| c.is_numeric())) {
            hour_str = part;
            found_time = true;
        } else if found_time && (part.eq_ignore_ascii_case("am") || part.eq_ignore_ascii_case("pm"))
        {
            am_pm = part;
            break;
        }
    }

    if !found_time || am_pm.is_empty() {
        return None;
    }

    let parts: Vec<&str> = hour_str.split(':').collect();
    let mut hour: u32 = parts[0].parse().ok()?;
    let minute: u32 = if parts.len() > 1 {
        parts[1].parse().ok()?
    } else {
        0
    };

    if am_pm.eq_ignore_ascii_case("pm") && hour != 12 {
        hour += 12;
    }
    if am_pm.eq_ignore_ascii_case("am") && hour == 12 {
        hour = 0;
    }

    Time::from_hms(hour as u8, minute as u8, 0).ok()
}

fn resolve_datetime(date: Option<Date>, time: Option<Time>) -> Option<OffsetDateTime> {
    date.map(|d| {
        let t = time.unwrap_or(Time::MIDNIGHT);
        OffsetDateTime::new_utc(d, t)
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn dc9_parses_fixture() {
        let html = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/dc9-events.html"
        ));
        let events = Dc9Scraper::parse(html).expect("Parse failed");
        assert!(!events.is_empty(), "Should parse ≥1 event");
        let first = &events[0];
        assert!(!first.title.is_empty(), "Title must be non-empty");
        assert_eq!(first.venue_name, "DC9");
        assert!(first.start_time > OffsetDateTime::UNIX_EPOCH);
    }
}
