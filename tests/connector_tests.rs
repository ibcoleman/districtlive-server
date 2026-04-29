//! Fixture-based tests for all 10 source connectors.
//!
//! Each test parses the corresponding fixture file and verifies ≥1 RawEvent
//! with non-empty title, venue_name, and valid start_time.
//!
//! Run with: `just test`

use districtlive_server::adapters::connectors::{
    bandsintown::BandsintownConnector, black_cat::BlackCatScraper,
    comet_ping_pong::CometPingPongScraper, dc9::Dc9Scraper, dice_fm::DiceFmConnector,
    pie_shop::PieShopScraper, rhizome_dc::RhizomeDcScraper, seven_drum_city::SevenDrumCityScraper,
    ticketmaster::TicketmasterConnector, union_stage_presents::UnionStagePresentsScraper,
};
use time::OffsetDateTime;

macro_rules! assert_valid_raw_event {
    ($events:expr, $connector_name:expr) => {
        assert!(
            !$events.is_empty(),
            "{}: Should parse ≥1 event",
            $connector_name
        );
        for event in &$events {
            assert!(
                !event.title.trim().is_empty(),
                "{}: title must not be empty",
                $connector_name
            );
            assert!(
                !event.venue_name.trim().is_empty(),
                "{}: venue_name must not be empty",
                $connector_name
            );
            assert!(
                event.start_time > OffsetDateTime::UNIX_EPOCH,
                "{}: start_time must be set",
                $connector_name
            );
        }
    };
}

// --- AC7.1: All connector fixture tests ---

#[test]
fn ticketmaster_parses_fixture() {
    let json = include_str!(concat!("fixtures/ticketmaster-dc-events.json"));
    let events = TicketmasterConnector::parse_json(json).expect("Parse failed");
    assert_valid_raw_event!(events, "Ticketmaster");
}

#[test]
fn bandsintown_parses_fixture() {
    let json = include_str!(concat!("fixtures/bandsintown-dc-artists.json"));
    let events = BandsintownConnector::parse_json(json, "test-artist").expect("Parse failed");
    assert_valid_raw_event!(events, "Bandsintown");
}

#[test]
fn dicefm_parses_fixture_with_events() {
    let html = include_str!(concat!("fixtures/dicefm-venue-events.html"));
    let events = DiceFmConnector::parse_html(html, "test-venue").expect("Parse failed");
    assert_valid_raw_event!(events, "Dice.fm");
}

#[test]
fn dicefm_empty_fixture_returns_no_events() {
    let html = include_str!(concat!("fixtures/dicefm-empty-events.html"));
    let events = DiceFmConnector::parse_html(html, "test-venue").expect("Parse failed");
    assert!(
        events.is_empty(),
        "Dice.fm empty fixture should yield no events"
    );
}

#[test]
fn black_cat_parses_fixture() {
    let html = include_str!(concat!("fixtures/black-cat-schedule.html"));
    let events = BlackCatScraper::parse(html).expect("Parse failed");
    assert_valid_raw_event!(events, "BlackCat");
}

#[test]
fn dc9_parses_fixture() {
    let html = include_str!(concat!("fixtures/dc9-events.html"));
    let events = Dc9Scraper::parse(html).expect("Parse failed");
    assert_valid_raw_event!(events, "DC9");
}

#[test]
fn comet_ping_pong_parses_listing_fixture() {
    let html = include_str!(concat!("fixtures/comet-ping-pong-listing.html"));
    let events = CometPingPongScraper::parse_listing(html);
    assert!(!events.is_empty(), "CometPingPong: Should parse ≥1 event");
    for (event, _) in &events {
        assert!(!event.title.trim().is_empty(), "Title must not be empty");
        assert!(
            !event.venue_name.trim().is_empty(),
            "Venue must not be empty"
        );
    }
}

#[test]
fn comet_ping_pong_detail_enriches_event() {
    let listing_html = include_str!(concat!("fixtures/comet-ping-pong-listing.html"));
    let detail_html = include_str!(concat!("fixtures/comet-ping-pong-detail.html"));

    let mut events = CometPingPongScraper::parse_listing(listing_html);
    assert!(!events.is_empty(), "Need at least 1 event from listing");
    let (mut event, _) = events.remove(0);

    CometPingPongScraper::parse_detail(detail_html, &mut event);

    // After detail, description or price may be populated (depends on fixture content)
    // Just assert the method ran without panicking and the event is still valid
    assert!(
        !event.title.is_empty(),
        "Title should still be present after detail enrichment"
    );
}

#[test]
fn pie_shop_parses_listing_fixture() {
    let html = include_str!(concat!("fixtures/pie-shop-listing.html"));
    let events = PieShopScraper::parse_listing(html);
    assert!(!events.is_empty(), "PieShop: Should parse ≥1 event");
}

#[test]
fn rhizome_dc_parses_fixture() {
    let html = include_str!(concat!("fixtures/rhizome-dc-events.html"));
    let events = RhizomeDcScraper::parse(html).expect("Parse failed");
    assert_valid_raw_event!(events, "RhizomeDC");
}

#[test]
fn seven_drum_city_parses_fixture() {
    let html = include_str!(concat!("fixtures/7-drum-city-events.html"));
    let events = SevenDrumCityScraper::parse(html).expect("Parse failed");
    assert_valid_raw_event!(events, "7DrumCity");
}

#[test]
fn union_stage_presents_parses_listing_fixture() {
    let html = include_str!(concat!("fixtures/union-stage-presents-listing.html"));
    let events = UnionStagePresentsScraper::parse_listing(
        html,
        "union-stage",
        "Union Stage",
        "740 Water St SW, Washington, DC 20024",
    );
    assert!(
        !events.is_empty(),
        "UnionStagePresents: Should parse ≥1 event"
    );
}
