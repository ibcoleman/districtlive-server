//! Source connector adapter implementations.

use scraper::{ElementRef, Selector};

pub mod bandsintown;
pub mod black_cat;
pub mod comet_ping_pong;
pub mod dc9;
pub mod dice_fm;
pub mod pie_shop;
pub mod rhizome_dc;
pub mod seven_drum_city;
pub mod ticketmaster;
pub mod union_stage_presents;

pub use bandsintown::BandsintownConnector;
pub use black_cat::BlackCatScraper;
pub use comet_ping_pong::CometPingPongScraper;
pub use dc9::Dc9Scraper;
pub use dice_fm::DiceFmConnector;
pub use pie_shop::PieShopScraper;
pub use rhizome_dc::RhizomeDcScraper;
pub use seven_drum_city::SevenDrumCityScraper;
pub use ticketmaster::TicketmasterConnector;
pub use union_stage_presents::UnionStagePresentsScraper;

/// Return a full URL given an href and an origin.
///
/// Relative hrefs (starting with `/`) are prefixed with `origin`; absolute hrefs
/// are returned unchanged.
pub(super) fn resolve_url(href: &str, origin: &str) -> String {
    if href.starts_with('/') {
        format!("{origin}{href}")
    } else {
        href.to_owned()
    }
}

/// Generate a stable identifier for a raw event from its title and date string.
///
/// The identifier is a 16-character lowercase hex string derived from a hash of
/// `"title|date_text"`. The same title+date always produces the same ID, making
/// ingestion runs idempotent for repeated scrapes of the same page.
pub(super) fn generate_source_id(title: &str, date_text: &str) -> String {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};
    let mut hasher = DefaultHasher::new();
    format!("{}|{}", title, date_text).hash(&mut hasher);
    format!("{:016x}", hasher.finish())
}

/// Extract trimmed text content from the first element matching `selector` within `parent`.
///
/// Returns an empty string if no matching element is found.
pub(super) fn select_text(parent: ElementRef<'_>, selector: &Selector) -> String {
    parent
        .select(selector)
        .next()
        .map(|e| e.text().collect::<String>())
        .unwrap_or_default()
        .trim()
        .to_owned()
}
