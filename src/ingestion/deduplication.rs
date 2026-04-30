//! Deduplication service — merges NormalizedEvents that represent the same event.
//!
//! Two events are considered duplicates if:
//! 1. (Primary) Same venue name (case-insensitive), same calendar date (ET), and
//!    title Jaro-Winkler similarity > 0.85
//! 2. (Secondary) Same calendar date (ET) and at least one shared artist name
// pattern: Functional Core

use strsim::jaro_winkler;

use crate::{
    domain::event::{DeduplicatedEvent, NormalizedEvent},
    ingestion::normalization::date_in_eastern_time_str,
};

/// Threshold for Jaro-Winkler title similarity to consider two events the same.
const SIMILARITY_THRESHOLD: f64 = 0.85;

pub struct DeduplicationService;

impl DeduplicationService {
    /// Deduplicate a list of normalized events.
    ///
    /// Returns one `DeduplicatedEvent` per unique real-world event, with all
    /// source attributions merged. When events merge, the fields from the
    /// highest-confidence source win.
    pub fn deduplicate(&self, events: Vec<NormalizedEvent>) -> Vec<DeduplicatedEvent> {
        let mut groups: Vec<Vec<NormalizedEvent>> = Vec::new();

        'outer: for event in events {
            // Try to find an existing group this event belongs to
            for group in &mut groups {
                let representative = &group[0];
                if self.are_duplicates(representative, &event) {
                    group.push(event);
                    continue 'outer;
                }
            }
            // No match — start a new group
            groups.push(vec![event]);
        }

        groups.into_iter().map(merge_group).collect()
    }

    fn are_duplicates(&self, a: &NormalizedEvent, b: &NormalizedEvent) -> bool {
        let date_a = date_in_eastern_time_str(a.raw.start_time);
        let date_b = date_in_eastern_time_str(b.raw.start_time);

        if date_a != date_b {
            return false;
        }

        // Primary match: same venue + high title similarity
        let same_venue = a.raw.venue_name.to_lowercase() == b.raw.venue_name.to_lowercase();
        if same_venue {
            let similarity = jaro_winkler(&a.raw.title.to_lowercase(), &b.raw.title.to_lowercase());
            if similarity >= SIMILARITY_THRESHOLD {
                return true;
            }
        }

        // Secondary match: shared artist name
        let has_shared_artist = a.raw.artist_names.iter().any(|artist_a| {
            b.raw
                .artist_names
                .iter()
                .any(|artist_b| artist_a.to_lowercase() == artist_b.to_lowercase())
        });

        has_shared_artist
    }
}

/// Merge a group of duplicate events into one `DeduplicatedEvent`.
///
/// The event with the highest confidence_score provides the canonical field values.
/// All source attributions from all events in the group are retained.
fn merge_group(mut group: Vec<NormalizedEvent>) -> DeduplicatedEvent {
    use crate::domain::event_source::SourceAttribution;

    // Sort by confidence score descending — highest confidence becomes canonical
    group.sort_by(|a, b| {
        b.raw
            .confidence_score
            .partial_cmp(&a.raw.confidence_score)
            .unwrap_or(std::cmp::Ordering::Equal)
    });

    let canonical = group.remove(0);

    // Merge artist names across all sources (union, preserve order)
    let mut all_artists: Vec<String> = canonical.raw.artist_names.clone();
    for other in &group {
        for artist in &other.raw.artist_names {
            if !all_artists
                .iter()
                .any(|a| a.to_lowercase() == artist.to_lowercase())
            {
                all_artists.push(artist.clone());
            }
        }
    }

    // Collect all source attributions
    let mut sources: Vec<SourceAttribution> = vec![attribution_from(&canonical)];
    for other in &group {
        sources.push(attribution_from(other));
    }

    // Rebuild canonical with merged artist list
    let mut merged = canonical;
    merged.raw.artist_names = all_artists;

    DeduplicatedEvent {
        event: merged,
        sources,
    }
}

fn attribution_from(event: &NormalizedEvent) -> crate::domain::event_source::SourceAttribution {
    use crate::domain::event_source::SourceAttribution;
    SourceAttribution {
        source_type: event.raw.source_type,
        source_identifier: event.raw.source_identifier.clone(),
        source_url: event.raw.source_url.clone(),
        confidence_score: event.raw.confidence_score,
        source_id: None, // Resolved at upsert time
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{event::RawEvent, source::SourceType};
    use rust_decimal::Decimal;
    use time::OffsetDateTime;

    fn make_normalized(slug: &str, source_identifier: &str) -> NormalizedEvent {
        NormalizedEvent {
            slug: slug.to_owned(),
            raw: RawEvent {
                source_type: SourceType::VenueScraper,
                source_identifier: Some(source_identifier.to_owned()),
                source_url: None,
                title: "Test Artist Live".to_owned(),
                description: None,
                venue_name: "Black Cat".to_owned(),
                venue_address: None,
                artist_names: vec!["Test Artist".to_owned()],
                start_time: OffsetDateTime::from_unix_timestamp(1_750_000_000).unwrap(),
                end_time: None,
                doors_time: None,
                min_price: None,
                max_price: None,
                ticket_url: None,
                image_url: None,
                age_restriction: None,
                genres: vec![],
                confidence_score: Decimal::new(70, 2),
            },
        }
    }

    // AC3.3 — Two NormalizedEvents with identical slugs deduplicate to one DeduplicatedEvent.
    #[test]
    fn deduplication_merges_matching_slugs() {
        let service = DeduplicationService;

        // Same slug, different source identifiers — same real-world event from two sources.
        let event1 = make_normalized("test-artist-live-black-cat-2025-06-15", "source-id-001");
        let event2 = make_normalized("test-artist-live-black-cat-2025-06-15", "source-id-002");

        let result = service.deduplicate(vec![event1, event2]);

        assert_eq!(
            result.len(),
            1,
            "Two events with matching slugs must deduplicate to exactly one DeduplicatedEvent"
        );
        assert_eq!(
            result[0].sources.len(),
            2,
            "Merged event must retain both source attributions"
        );
    }
}
