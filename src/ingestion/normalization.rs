//! Normalization service — cleans RawEvents and generates URL-safe slugs.
// pattern: Functional Core

use chrono_tz::America::New_York;
use time::OffsetDateTime;

use crate::domain::{
    event::{NormalizedEvent, RawEvent},
    slugify,
};

/// Title prefixes that are stripped before slug generation.
const TITLE_STRIP_PREFIXES: &[&str] = &[
    "an evening with ",
    "a evening with ",
    "evening with ",
    "evening: ",
    "with ",
    "am ",
];

/// Normalized title values that indicate a placeholder event.
const PLACEHOLDER_TITLES: &[&str] = &[
    "private event",
    "tba",
    "to be announced",
    "coming soon",
    "sold out",
];

pub struct NormalizationService;

impl NormalizationService {
    pub fn normalize(&self, events: Vec<RawEvent>) -> Vec<NormalizedEvent> {
        events
            .into_iter()
            .filter_map(|raw| {
                if raw.title.trim().is_empty() {
                    tracing::debug!("Dropping event with blank title");
                    return None;
                }
                let slug = generate_slug(&raw.title, &raw.venue_name, raw.start_time);
                Some(NormalizedEvent { raw, slug })
            })
            .collect()
    }

    /// Returns `true` if the title is a known placeholder (should be filtered out before upsert).
    pub fn is_placeholder(title: &str) -> bool {
        let normalized = title.trim().to_lowercase();
        PLACEHOLDER_TITLES.contains(&normalized.as_str()) || normalized.starts_with("sold out:")
    }
}

/// Clean a raw event title by stripping common filler prefixes.
fn clean_title(title: &str) -> String {
    let lower = title.trim().to_lowercase();
    for prefix in TITLE_STRIP_PREFIXES {
        if lower.starts_with(prefix) {
            return title.trim()[prefix.len()..].trim().to_owned();
        }
    }
    title.trim().to_owned()
}

/// Generate a URL-safe slug: `"{cleaned_title} {venue_name} {date}"` → kebab-case.
pub fn generate_slug(title: &str, venue_name: &str, start_time: OffsetDateTime) -> String {
    let cleaned_title = clean_title(title);
    let date_str = date_in_eastern_time_str(start_time);
    let raw = format!("{} {} {}", cleaned_title, venue_name, date_str);
    slugify(&raw)
}

/// Convert `OffsetDateTime` to `yyyy-MM-dd` in America/New_York timezone.
pub fn date_in_eastern_time_str(dt: OffsetDateTime) -> String {
    let unix_ts = dt.unix_timestamp();
    let chrono_utc =
        chrono::DateTime::<chrono::Utc>::from_timestamp(unix_ts, 0).unwrap_or_default();
    let et = chrono_utc.with_timezone(&New_York);
    et.format("%Y-%m-%d").to_string()
}

/// Strip artist names that are obviously placeholder values.
pub fn clean_artist_name(name: &str) -> Option<String> {
    let lower = name.trim().to_lowercase();
    if matches!(
        lower.as_str(),
        "special guest" | "special guests" | "tba" | "to be announced"
    ) {
        return None;
    }
    let cleaned = name.trim().to_owned();
    if cleaned.is_empty() {
        None
    } else {
        Some(cleaned)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // AC3.7 — is_placeholder returns true for all known placeholder title values.
    #[test]
    fn placeholder_titles_are_filtered() {
        assert!(
            NormalizationService::is_placeholder("TBA"),
            "TBA must be a placeholder"
        );
        assert!(
            NormalizationService::is_placeholder("To Be Announced"),
            "To Be Announced must be a placeholder"
        );
        assert!(
            NormalizationService::is_placeholder("private event"),
            "private event must be a placeholder"
        );
        assert!(
            NormalizationService::is_placeholder("Coming Soon"),
            "Coming Soon must be a placeholder"
        );
        assert!(
            NormalizationService::is_placeholder("Sold Out"),
            "Sold Out must be a placeholder"
        );
        assert!(
            !NormalizationService::is_placeholder("Real Artist Name"),
            "A real artist name must not be flagged as a placeholder"
        );
    }
}
