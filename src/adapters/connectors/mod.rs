//! Source connector adapter implementations.

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

// Given an href and origin, return a full URL
fn resolve_url(href: &str, origin: &str) -> String {
    if href.starts_with('/') {
        format!("{origin}{href}")
    } else {
        href.to_owned()
    }
}
