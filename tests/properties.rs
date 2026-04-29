//! Property-based tests for domain type invariants.

use districtlive_server::domain::{artist::ArtistId, venue::VenueId, Pagination};
use proptest::prelude::*;
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
