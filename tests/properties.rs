//! Property-based tests for domain type invariants.

use districtlive_server::domain::event::RawEvent;
use districtlive_server::domain::{artist::ArtistId, venue::VenueId, Pagination};
use districtlive_server::ingestion::{
    deduplication::DeduplicationService,
    normalization::{generate_slug, NormalizationService},
};
use proptest::prelude::*;
use rust_decimal::Decimal;
use time::OffsetDateTime;
use uuid::Uuid;

proptest! {
    // --- ID newtype invariants ---

    /// Two VenueIds wrapping the same UUID must be equal.
    /// This verifies the PartialEq derive correctly delegates to the inner Uuid.
    #[test]
    fn venue_id_equality_reflexive(bytes in prop::array::uniform16(0u8..)) {
        let uuid = Uuid::from_bytes(bytes);
        let id_a = VenueId(uuid);
        let id_b = VenueId(uuid);
        prop_assert_eq!(id_a, id_b);
    }

    /// Two ArtistIds wrapping different UUIDs must not be equal.
    #[test]
    fn artist_id_inequality(
        bytes_a in prop::array::uniform16(0u8..),
        bytes_b in prop::array::uniform16(0u8..),
    ) {
        let uuid_a = Uuid::from_bytes(bytes_a);
        let uuid_b = Uuid::from_bytes(bytes_b);
        prop_assume!(uuid_a != uuid_b);
        prop_assert_ne!(ArtistId(uuid_a), ArtistId(uuid_b));
    }

    // --- Pagination invariants ---

    /// First page always has offset 0, regardless of per_page.
    #[test]
    fn pagination_first_page_offset_is_zero(per_page in 1i64..200) {
        let p = Pagination { page: 0, per_page };
        prop_assert_eq!(p.offset(), 0);
    }

    /// Each additional page advances by exactly one per_page.
    #[test]
    fn pagination_offset_advances_by_per_page(page in 0i64..999, per_page in 1i64..200) {
        let p_current = Pagination { page, per_page };
        let p_next = Pagination { page: page + 1, per_page };
        prop_assert_eq!(p_next.offset() - p_current.offset(), per_page);
    }

    /// Offset must be non-negative for non-negative page and positive per_page.
    #[test]
    fn pagination_offset_non_negative(page in 0i64..1000, per_page in 1i64..200) {
        let p = Pagination { page, per_page };
        prop_assert!(p.offset() >= 0);
    }
}

/// Default pagination has page=0 offset=0.
#[test]
fn pagination_default_offset_is_zero() {
    let p = Pagination::default();
    assert_eq!(p.offset(), 0);
}

// --- AC7.2: Normalization invariants ---

proptest! {
    /// Slug is always non-empty for any non-empty title + venue combination.
    #[test]
    fn slug_is_non_empty_for_valid_input(
        title in "[a-zA-Z0-9 ]{1,100}",
        venue in "[a-zA-Z0-9 ]{1,50}",
    ) {
        let slug = generate_slug(&title, &venue, OffsetDateTime::now_utc());
        prop_assert!(!slug.is_empty(), "Slug must be non-empty");
    }

    /// Slug is URL-safe: only lowercase alphanumeric + hyphens, no leading/trailing hyphens.
    #[test]
    fn slug_is_url_safe(
        title in "[a-zA-Z0-9 !@#$%^&*()]{1,100}",
        venue in "[a-zA-Z0-9 !@#$%]{1,50}",
    ) {
        let slug = generate_slug(&title, &venue, OffsetDateTime::now_utc());
        prop_assert!(
            slug.chars().all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '-'),
            "Slug must be URL-safe: got {slug:?}"
        );
        prop_assert!(!slug.starts_with('-'), "Slug must not start with hyphen");
        prop_assert!(!slug.ends_with('-'), "Slug must not end with hyphen");
    }

    /// Normalization preserves start_time unchanged.
    #[test]
    fn normalization_preserves_start_time(
        unix_sec in 1_700_000_000i64..1_900_000_000i64
    ) {
        let dt = OffsetDateTime::from_unix_timestamp(unix_sec).unwrap();
        let raw = make_raw_event("Test Artist Live Show", "Black Cat", dt);
        let service = NormalizationService;
        let normalized = service.normalize(vec![raw]);
        prop_assert_eq!(normalized.len(), 1);
        prop_assert_eq!(normalized[0].raw.start_time, dt, "start_time must be preserved");
    }
}

// --- AC7.3: Deduplication idempotency ---

proptest! {
    /// Deduplicating an already-deduplicated list produces the same result.
    #[test]
    fn deduplication_is_idempotent(
        num_events in 1usize..10,
    ) {
        let service = DeduplicationService;
        // Create events at distinct venues + dates to avoid merging
        let events: Vec<_> = (0..num_events).map(|i| {
            let dt = OffsetDateTime::from_unix_timestamp(1_750_000_000 + i as i64 * 86400).unwrap();
            let raw = make_raw_event(
                &format!("Event {i}"),
                &format!("Venue {i}"),
                dt,
            );
            districtlive_server::domain::event::NormalizedEvent {
                slug: format!("event-{i}-venue-{i}-2025-06-{:02}", i + 1),
                raw,
            }
        }).collect();

        let first_pass = service.deduplicate(events.clone());
        let first_slugs: Vec<_> = first_pass.iter().map(|e| e.event.slug.clone()).collect();

        // Convert back and deduplicate again
        let second_pass = service.deduplicate(
            first_pass.into_iter().map(|d| d.event).collect()
        );
        let second_slugs: Vec<_> = second_pass.iter().map(|e| e.event.slug.clone()).collect();

        prop_assert_eq!(first_slugs, second_slugs, "Deduplication must be idempotent");
    }
}

fn make_raw_event(title: &str, venue_name: &str, start_time: OffsetDateTime) -> RawEvent {
    use districtlive_server::domain::source::SourceType;
    RawEvent {
        source_type: SourceType::VenueScraper,
        source_identifier: None,
        source_url: None,
        title: title.to_owned(),
        description: None,
        venue_name: venue_name.to_owned(),
        venue_address: None,
        artist_names: vec![title.to_owned()],
        start_time,
        end_time: None,
        doors_time: None,
        min_price: None,
        max_price: None,
        ticket_url: None,
        image_url: None,
        age_restriction: None,
        genres: vec![],
        confidence_score: Decimal::new(70, 2),
    }
}
