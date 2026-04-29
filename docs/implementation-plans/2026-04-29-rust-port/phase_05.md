# DistrictLive Rust Port — Phase 5: Ingestion Pipeline

**Goal:** All source connectors implemented and tested against fixture files. Normalization, deduplication, and orchestration pipeline runs end-to-end. Scheduler activates when `INGESTION_ENABLED=true`.

**Architecture:** `src/ingestion/` holds pure pipeline logic (normalization, deduplication, orchestrator, scheduler). Connectors live in `src/adapters/connectors/`. All connectors implement `SourceConnector` from Phase 2. Normalization is pure: `Vec<RawEvent> → Vec<NormalizedEvent>`. Deduplication uses Jaro-Winkler similarity (`strsim`) for title matching. The orchestrator holds `Arc<dyn EventRepository>` and `Arc<dyn IngestionRunRepository>` from Phase 3.

**Tech Stack:** `scraper` 0.26, `reqwest` 0.12, `strsim` 0.11, `chrono` + `chrono-tz` (for America/New_York date extraction in slugs), `tokio-cron-scheduler` 0.15, `serde_json`

**Scope:** Phase 5 of 7 from original design

**Codebase verified:** 2026-04-29

---

## Acceptance Criteria Coverage

### rust-port.AC3: Ingestion pipeline
- **rust-port.AC3.1 Success:** Each of the 10+ connectors parses its fixture file and produces ≥1 `RawEvent` with non-empty title, venue name, and start time
- **rust-port.AC3.2 Success:** Normalization produces a non-empty URL-safe slug for every `RawEvent`
- **rust-port.AC3.3 Success:** Deduplication groups events with matching slugs into a single `DeduplicatedEvent` with merged source attributions
- **rust-port.AC3.4 Success:** `POST /api/admin/ingest/trigger` when `INGESTION_ENABLED=true` completes and returns stats (fetched, created, updated, deduped)
- **rust-port.AC3.5 Success:** An `IngestionRun` record is written as RUNNING on pipeline start and updated to SUCCESS on completion
- **rust-port.AC3.6 Success:** Running the same connector twice updates the existing event record (slug match → UPDATE, not INSERT duplicate)
- **rust-port.AC3.7 Failure:** Events with placeholder titles (`"private event"`, `"tba"`, `"sold out"`, `"coming soon"`) are dropped before upsert
- **rust-port.AC3.8 Failure:** `POST /api/admin/ingest/trigger` when `INGESTION_ENABLED=false` returns 400 with an explanatory error message

### rust-port.AC7: Test coverage (partial)
- **rust-port.AC7.1 Success:** All 10+ connector fixture tests pass with `just test`
- **rust-port.AC7.2 Success:** Normalization property tests pass: slug is always non-empty and URL-safe; start_time is always preserved unchanged
- **rust-port.AC7.3 Success:** Deduplication idempotency property test passes: deduplicating an already-deduplicated list produces the same result

---

## Prerequisite: Add new crates to Cargo.toml

Read `Cargo.toml`. Add to `[dependencies]`:

```toml
# Fuzzy string similarity for event deduplication (Jaro-Winkler)
strsim = "0.11"

# Timezone-aware date extraction for slug generation (America/New_York)
chrono = "0.4"
chrono-tz = "0.10"
```

Then:

```bash
cargo update
just bazel-repin
```

---

<!-- START_SUBCOMPONENT_A (tasks 1-3) -->

<!-- START_TASK_1 -->
### Task 1: Fixture files + module skeleton

**Verifies:** None (infrastructure)

**Files:**
- Create: `tests/fixtures/` directory with all fixture files
- Update: `src/ingestion/mod.rs` — add submodule declarations
- Create: `src/adapters/connectors/mod.rs`

**Step 1: Copy fixture files from Kotlin test resources**

```bash
mkdir -p tests/fixtures
cp kotlin-src/src/test/resources/fixtures/*.html tests/fixtures/
cp kotlin-src/src/test/resources/fixtures/*.json tests/fixtures/
```

Expected: 15 fixture files copied:
```
tests/fixtures/
  7-drum-city-events.html
  black-cat-schedule.html
  comet-ping-pong-detail.html
  comet-ping-pong-empty.html
  comet-ping-pong-listing.html
  dc9-events.html
  dicefm-empty-events.html
  dicefm-mixed-events.html
  dicefm-no-jsonld.html
  dicefm-second-venue-events.html
  dicefm-venue-events.html
  events.json
  pie-shop-detail.html
  pie-shop-empty.html
  pie-shop-listing.html
  rhizome-dc-events.html
  ticketmaster-dc-events.json
  union-stage-presents-detail.html
  union-stage-presents-empty.html
  union-stage-presents-listing.html
```

**Step 2: Update src/ingestion/mod.rs**

```rust
//! Ingestion pipeline — normalization, deduplication, orchestration, and scheduling.

pub mod deduplication;
pub mod normalization;
pub mod orchestrator;
pub mod scheduler;
```

**Step 3: Create src/adapters/connectors/mod.rs**

```rust
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
```

Update `src/adapters/mod.rs` to add `pub mod connectors;`.

**Step 4: Add shared HTTP client to AppState**

In `src/http/mod.rs`, add `pub http_client: reqwest::Client` to `AppState`. This allows all connectors to share a single connection pool.

In `src/main.rs`, create the client at startup:

```rust
let http_client = reqwest::Client::builder()
    .timeout(std::time::Duration::from_secs(30))
    .user_agent(format!(
        "districtlive-server/{} (https://districtlive.com)",
        env!("CARGO_PKG_VERSION")
    ))
    .build()
    .expect("Failed to build HTTP client");
```

Pass it as `AppState { ..., http_client }`.

**Commit:** `chore: fixture files, ingestion module skeleton, shared HTTP client`
<!-- END_TASK_1 -->

<!-- START_TASK_2 -->
### Task 2: Normalization service

**Verifies:** rust-port.AC3.2, rust-port.AC3.7, rust-port.AC7.2

**Files:**
- Create: `src/ingestion/normalization.rs`

The normalization service converts `RawEvent`s to `NormalizedEvent`s. The slug formula is:
```
slug = kebab(cleanTitle + " " + venueName + " " + date(yyyy-MM-dd in America/New_York))
```

```rust
//! Normalization service — cleans RawEvents and generates URL-safe slugs.

use chrono::TimeZone;
use chrono_tz::America::New_York;
use time::OffsetDateTime;

use crate::domain::{
    error::IngestionError,
    event::{NormalizedEvent, RawEvent},
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
        PLACEHOLDER_TITLES.contains(&normalized.as_str())
            || normalized.starts_with("sold out:")
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
    let date_str = date_in_eastern_time(start_time);
    let raw = format!("{} {} {}", cleaned_title, venue_name, date_str);
    slugify(&raw)
}

/// Convert `OffsetDateTime` to `yyyy-MM-dd` in America/New_York timezone.
fn date_in_eastern_time(dt: OffsetDateTime) -> String {
    let unix_ts = dt.unix_timestamp();
    let chrono_utc = chrono::DateTime::<chrono::Utc>::from_timestamp(unix_ts, 0)
        .unwrap_or_default();
    let et = chrono_utc.with_timezone(&New_York);
    et.format("%Y-%m-%d").to_string()
}

// Use the canonical slugify from domain::mod (defined in Phase 2 Task 1).
// Import it in normalization.rs: `use crate::domain::slugify;`
// DO NOT redefine slugify here — there must be a single canonical implementation.

/// Strip artist names that are obviously placeholder values.
pub fn clean_artist_name(name: &str) -> Option<String> {
    let lower = name.trim().to_lowercase();
    if matches!(lower.as_str(), "special guest" | "special guests" | "tba" | "to be announced") {
        return None;
    }
    let cleaned = name.trim().to_owned();
    if cleaned.is_empty() { None } else { Some(cleaned) }
}
```

**Commit:** `feat: normalization service with slug generation and placeholder filtering`
<!-- END_TASK_2 -->

<!-- START_TASK_3 -->
### Task 3: Deduplication service

**Verifies:** rust-port.AC3.3, rust-port.AC7.3

**Files:**
- Create: `src/ingestion/deduplication.rs`

The deduplication service groups `NormalizedEvent`s that likely represent the same real-world event. Primary matching: same venue + same date + Jaro-Winkler title similarity > 0.85. Secondary matching: same date + shared artist name.

```rust
//! Deduplication service — merges NormalizedEvents that represent the same event.
//!
//! Two events are considered duplicates if:
//! 1. (Primary) Same venue name (case-insensitive), same calendar date (ET), and
//!    title Jaro-Winkler similarity > 0.85
//! 2. (Secondary) Same calendar date (ET) and at least one shared artist name

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
        let same_venue =
            a.raw.venue_name.to_lowercase() == b.raw.venue_name.to_lowercase();
        if same_venue {
            let similarity = jaro_winkler(
                &a.raw.title.to_lowercase(),
                &b.raw.title.to_lowercase(),
            );
            if similarity >= SIMILARITY_THRESHOLD {
                return true;
            }
        }

        // Secondary match: shared artist name
        let has_shared_artist = a.raw.artist_names.iter().any(|artist_a| {
            b.raw.artist_names.iter().any(|artist_b| {
                artist_a.to_lowercase() == artist_b.to_lowercase()
            })
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
        b.raw.confidence_score
            .partial_cmp(&a.raw.confidence_score)
            .unwrap_or(std::cmp::Ordering::Equal)
    });

    let canonical = group.remove(0);

    // Merge artist names across all sources (union, preserve order)
    let mut all_artists: Vec<String> = canonical.raw.artist_names.clone();
    for other in &group {
        for artist in &other.raw.artist_names {
            if !all_artists.iter().any(|a| a.to_lowercase() == artist.to_lowercase()) {
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

    DeduplicatedEvent { event: merged, sources }
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
```

Update `src/ingestion/normalization.rs` to expose `date_in_eastern_time_str` as a `pub fn` (used by deduplication):

```rust
/// Returns `"yyyy-MM-dd"` in America/New_York timezone. Public for use in deduplication.
pub fn date_in_eastern_time_str(dt: time::OffsetDateTime) -> String {
    // Same as date_in_eastern_time — extract to shared pub fn
    date_in_eastern_time(dt)
}
```

**Commit:** `feat: deduplication service with Jaro-Winkler primary match + shared artist secondary`
<!-- END_TASK_3 -->

<!-- END_SUBCOMPONENT_A -->

<!-- START_SUBCOMPONENT_B (tasks 4-6) -->

<!-- START_TASK_4 -->
### Task 4: JSON API connectors (Ticketmaster, Bandsintown, Dice.fm)

**Verifies:** rust-port.AC3.1 (for Ticketmaster, Bandsintown, Dice.fm)

**Files:**
- Create: `src/adapters/connectors/ticketmaster.rs`
- Create: `src/adapters/connectors/bandsintown.rs`
- Create: `src/adapters/connectors/dice_fm.rs`

**Reference:** Read the Kotlin connector files for full field mapping detail:
- `kotlin-src/src/main/kotlin/com/memetoclasm/districtlive/ingestion/connectors/TicketmasterConnector.kt`
- `kotlin-src/src/main/kotlin/com/memetoclasm/districtlive/ingestion/connectors/BandsintownConnector.kt`
- `kotlin-src/src/main/kotlin/com/memetoclasm/districtlive/ingestion/connectors/DiceFmConnector.kt`

**Ticketmaster connector structure:**

```rust
use async_trait::async_trait;
use reqwest::Client;
use rust_decimal::Decimal;
use time::OffsetDateTime;

use crate::{
    config::Config,
    domain::{error::IngestionError, event::RawEvent, source::SourceType},
    ports::SourceConnector,
};

pub struct TicketmasterConnector {
    client: Client,
    api_key: String,
    base_url: String, // default: "https://app.ticketmaster.com/discovery/v2"
}

impl TicketmasterConnector {
    pub fn new(client: Client, config: &Config) -> Option<Self> {
        config.ticketmaster_api_key.as_ref().map(|key| Self {
            client,
            api_key: key.clone(),
            base_url: "https://app.ticketmaster.com/discovery/v2".to_owned(),
        })
    }
}

#[async_trait]
impl SourceConnector for TicketmasterConnector {
    fn source_id(&self) -> &str { "ticketmaster" }
    fn source_type(&self) -> SourceType { SourceType::TicketmasterApi }

    async fn fetch(&self) -> Result<Vec<RawEvent>, IngestionError> {
        let url = format!("{}/events.json", self.base_url);
        let response = self.client
            .get(&url)
            .query(&[
                ("apikey", &self.api_key),
                ("classificationName", &"music".to_owned()),
                ("city", &"Washington".to_owned()),
                ("stateCode", &"DC".to_owned()),
                ("countryCode", &"US".to_owned()),
                ("size", &"200".to_owned()),
                ("sort", &"date,asc".to_owned()),
            ])
            .send()
            .await
            .map_err(|e| IngestionError::Http { url: url.clone(), source: e })?
            .json::<serde_json::Value>()
            .await
            .map_err(|e| IngestionError::Http { url: url.clone(), source: e })?;

        let events = response
            .get("_embedded")
            .and_then(|e| e.get("events"))
            .and_then(|e| e.as_array())
            .map(|arr| arr.as_slice())
            .unwrap_or(&[]);

        let mut raw_events = Vec::new();
        for event in events {
            // Filter: must be in Washington, DC
            let venue = event.get("_embedded")
                .and_then(|e| e.get("venues"))
                .and_then(|v| v.as_array())
                .and_then(|arr| arr.first());
            
            let city = venue.and_then(|v| v.get("city"))
                .and_then(|c| c.get("name"))
                .and_then(|n| n.as_str())
                .unwrap_or("");
            let state = venue.and_then(|v| v.get("state"))
                .and_then(|s| s.get("stateCode"))
                .and_then(|s| s.as_str())
                .unwrap_or("");
            
            if city != "Washington" || state != "DC" {
                continue;
            }

            // Parse start time
            let start_time = event.get("dates")
                .and_then(|d| d.get("start"))
                .and_then(|s| s.get("dateTime").or_else(|| s.get("localDate")))
                .and_then(|t| t.as_str())
                .and_then(|t| OffsetDateTime::parse(t, &time::format_description::well_known::Rfc3339).ok())
                .ok_or_else(|| IngestionError::Parse("Missing startTime in Ticketmaster event".to_owned()))?;

            let title = event.get("name").and_then(|n| n.as_str())
                .unwrap_or("").to_owned();
            if title.is_empty() { continue; }

            let venue_name = venue.and_then(|v| v.get("name"))
                .and_then(|n| n.as_str()).unwrap_or("").to_owned();

            let venue_address = venue.map(|v| {
                let line1 = v.get("address").and_then(|a| a.get("line1")).and_then(|l| l.as_str()).unwrap_or("");
                let city = v.get("city").and_then(|c| c.get("name")).and_then(|n| n.as_str()).unwrap_or("");
                format!("{}, {}", line1, city)
            });

            let artists = event.get("_embedded")
                .and_then(|e| e.get("attractions"))
                .and_then(|a| a.as_array())
                .map(|arr| arr.iter()
                    .filter_map(|a| a.get("name").and_then(|n| n.as_str()).map(str::to_owned))
                    .collect::<Vec<_>>())
                .unwrap_or_default();

            let min_price = event.get("priceRanges")
                .and_then(|p| p.as_array())
                .and_then(|p| p.first())
                .and_then(|p| p.get("min"))
                .and_then(|m| m.as_f64())
                .and_then(|f| Decimal::try_from(f).ok());

            let max_price = event.get("priceRanges")
                .and_then(|p| p.as_array())
                .and_then(|p| p.first())
                .and_then(|p| p.get("max"))
                .and_then(|m| m.as_f64())
                .and_then(|f| Decimal::try_from(f).ok());

            raw_events.push(RawEvent {
                source_type: SourceType::TicketmasterApi,
                source_identifier: event.get("id").and_then(|i| i.as_str()).map(str::to_owned),
                source_url: event.get("url").and_then(|u| u.as_str()).map(str::to_owned),
                title,
                description: None,
                venue_name,
                venue_address,
                artist_names: artists,
                start_time,
                end_time: None,
                doors_time: None,
                min_price,
                max_price,
                ticket_url: event.get("url").and_then(|u| u.as_str()).map(str::to_owned),
                image_url: event.get("images").and_then(|i| i.as_array())
                    .and_then(|a| a.first())
                    .and_then(|i| i.get("url"))
                    .and_then(|u| u.as_str()).map(str::to_owned),
                age_restriction: None,
                genres: vec![],
                confidence_score: Decimal::new(90, 2), // 0.90
            });
        }
        Ok(raw_events)
    }

    fn health_check(&self) -> bool {
        !self.api_key.is_empty()
    }
}
```

**Bandsintown connector:** Follow the same structure. Key differences:
- Iterates over `config.bandsintown_app_id` and a hardcoded list of DC artists from the Kotlin source
- Fetches `https://rest.bandsintown.com/artists/{artist}/events?app_id={id}&date=upcoming`
- Filters events where `venue.city` contains "washington" (case-insensitive) or `venue.region == "DC"`
- Source ID: `"bandsintown"`, SourceType: `BandsinTownApi`
- Reference: `BandsintownConnector.kt` for the seed artist list and DC filter logic

**Dice.fm connector:** Fetches HTML page, extracts `<script type="application/ld+json">` containing events:

```rust
// Selector for JSON-LD scripts
let selector = Selector::parse(r#"script[type="application/ld+json"]"#).unwrap();

for script in document.select(&selector) {
    let json_text: String = script.text().collect();
    let val: serde_json::Value = match serde_json::from_str(&json_text) {
        Ok(v) => v,
        Err(_) => continue,
    };
    
    // Look for @type == "Place" objects with nested events
    if val.get("@type").and_then(|t| t.as_str()) == Some("Place") {
        if let Some(events) = val.get("event").and_then(|e| e.as_array()) {
            for event_obj in events {
                if event_obj.get("@type").and_then(|t| t.as_str()) == Some("MusicEvent") {
                    // Extract: name, startDate, endDate, url, description, image, offers
                    // See DiceFmConnector.kt for full field mapping
                }
            }
        }
    }
}
```

**Unit tests for JSON API connectors:**

Add inline tests (or in `tests/connectors/ticketmaster.rs`) that load fixture files:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn ticketmaster_parses_fixture() {
        let fixture = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/ticketmaster-dc-events.json"
        ));
        // Create a mock response and verify parsing
        // For unit tests, parse the JSON directly without HTTP
        let json: serde_json::Value = serde_json::from_str(fixture).unwrap();
        let events_arr = json.get("_embedded")
            .and_then(|e| e.get("events"))
            .and_then(|e| e.as_array())
            .unwrap();
        assert!(!events_arr.is_empty(), "Fixture should contain events");
    }
}
```

For proper fixture-based tests that test the full parsing logic, create a test helper method on each connector that accepts a `serde_json::Value` instead of making an HTTP call. See Task 9 for the test structure.

**Commit:** `feat: Ticketmaster, Bandsintown, Dice.fm connectors`
<!-- END_TASK_4 -->

<!-- START_TASK_5 -->
### Task 5: Simple scrapers (BlackCat, DC9, Rhizome DC, 7 Drum City)

**Verifies:** rust-port.AC3.1 (for BlackCat, DC9, Rhizome, 7 Drum City)

**Files:**
- Create: `src/adapters/connectors/black_cat.rs`
- Create: `src/adapters/connectors/dc9.rs`
- Create: `src/adapters/connectors/rhizome_dc.rs`
- Create: `src/adapters/connectors/seven_drum_city.rs`

All four follow the same single-page scraper pattern. Read the corresponding Kotlin scraper for precise CSS selectors. The template for each:

```rust
use async_trait::async_trait;
use reqwest::Client;
use rust_decimal::Decimal;
use scraper::{Html, Selector};
use time::OffsetDateTime;

use crate::{
    domain::{error::IngestionError, event::RawEvent, source::SourceType},
    ports::SourceConnector,
};

pub struct BlackCatScraper {
    client: Client,
}

impl BlackCatScraper {
    pub fn new(client: Client) -> Self { Self { client } }
    
    /// Parse HTML document into RawEvents. Used by both fetch() and unit tests.
    pub fn parse(html: &str) -> Result<Vec<RawEvent>, IngestionError> {
        let document = Html::parse_document(html);
        
        // CSS selectors from BlackCatScraper.kt:
        let show_sel = Selector::parse("div.show")
            .map_err(|_| IngestionError::Parse("Invalid selector".into()))?;
        let title_sel = Selector::parse("h1.headline a")
            .map_err(|_| IngestionError::Parse("Invalid selector".into()))?;
        let date_sel = Selector::parse("h2.date")
            .map_err(|_| IngestionError::Parse("Invalid selector".into()))?;
        // ... other selectors
        
        let mut events = Vec::new();
        let current_year = chrono::Utc::now().format("%Y").to_string();
        
        for show in document.select(&show_sel) {
            let title = show.select(&title_sel)
                .next()
                .map(|e| e.text().collect::<String>().trim().to_owned())
                .unwrap_or_default();
            if title.is_empty() { continue; }
            
            let date_text = show.select(&date_sel)
                .next()
                .map(|e| e.text().collect::<String>().trim().to_owned())
                .unwrap_or_default();
            
            // Date parsing: Black Cat omits the year, so append current year
            // Try formats: "EEEE MMMM d yyyy", "MMMM d yyyy", "MMM d yyyy"
            let date_with_year = format!("{} {}", date_text, current_year);
            let start_time = parse_black_cat_date(&date_with_year)
                .ok_or_else(|| IngestionError::Parse(format!("Cannot parse date: {date_text}")))?;
            
            events.push(RawEvent {
                source_type: SourceType::VenueScraper,
                source_identifier: Some(generate_source_id(&title, &date_text)),
                source_url: None,
                title,
                description: None,
                venue_name: "Black Cat".to_owned(),
                venue_address: Some("1811 14th St NW, Washington, DC 20009".to_owned()),
                artist_names: vec![], // Parsed from title in normalization
                start_time,
                end_time: None,
                doors_time: None,
                min_price: None,
                max_price: None,
                ticket_url: show.select(&Selector::parse("div.show-details > a[href*='etix.com']").unwrap())
                    .next()
                    .and_then(|a| a.value().attr("href"))
                    .map(str::to_owned),
                image_url: None,
                age_restriction: None,
                genres: vec![],
                confidence_score: Decimal::new(70, 2), // 0.70
            });
        }
        Ok(events)
    }
}

#[async_trait]
impl SourceConnector for BlackCatScraper {
    fn source_id(&self) -> &str { "black-cat" }
    fn source_type(&self) -> SourceType { SourceType::VenueScraper }
    
    async fn fetch(&self) -> Result<Vec<RawEvent>, IngestionError> {
        let url = "https://www.blackcatdc.com/schedule.html";
        let html = self.client.get(url).send().await
            .map_err(|e| IngestionError::Http { url: url.to_owned(), source: e })?
            .text().await
            .map_err(|e| IngestionError::Http { url: url.to_owned(), source: e })?;
        Self::parse(&html)
    }
}

fn generate_source_id(title: &str, date_text: &str) -> String {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};
    let mut hasher = DefaultHasher::new();
    format!("{title}|{date_text}").hash(&mut hasher);
    format!("{:016x}", hasher.finish())
}

fn parse_black_cat_date(s: &str) -> Option<OffsetDateTime> {
    // Try format: "MMMM d yyyy" → time::Date parsing
    // The time crate uses format_description for parsing
    // Example: "April 15 2026" → OffsetDateTime::new_utc(Date::from_calendar_date(...), Time::from_hms(20,0,0).ok()?)
    let formats = [
        time::macros::format_description!("[weekday repr:long] [month repr:long] [day] [year]"),
        time::macros::format_description!("[month repr:long] [day] [year]"),
        time::macros::format_description!("[month repr:short] [day] [year]"),
    ];
    for fmt in &formats {
        if let Ok(date) = time::Date::parse(s, fmt) {
            let t = time::Time::from_hms(20, 0, 0).ok()?;
            return Some(OffsetDateTime::new_utc(date, t));
        }
    }
    None
}
```

**Key implementation notes per scraper:**

**DC9** (`dc9.rs`):
- URL: `https://dc9.club/`
- Container: `div.listing.plotCard[data-listing-id]` (dedup by `data-listing-id` attribute)
- Title: `div.listing__title h3`
- Date: `div.listingDateTime span` — format `"EEE, MMM d yyyy"` (append current year)
- Doors/show: `p.listing-doors` — extract with regex `(\d{1,2}(?::\d{2})?)(am|pm)`
- If date is >2 months in the past, add 1 year
- Hardcoded venue: `"DC9"`, `"1940 9th St NW, Washington, DC 20001"`

**Rhizome DC** (`rhizome_dc.rs`):
- URL: `https://www.rhizomedc.org/new-events`
- Container: `article.eventlist-event--upcoming`
- Title: `h1.eventlist-title a.eventlist-title-link`
- Date: `time.event-date` (attribute `datetime`, first 10 chars = `"yyyy-MM-dd"`)
- Time: `time.event-time-12hr-start` (text, format `"h:mm a"`)
- Price/ticket URL: extracted from `div.eventlist-excerpt` text via regex
- Confidence score: `0.80`

**Seven Drum City** (`seven_drum_city.rs`):
- URL: `https://thepocket.7drumcity.com`
- Container: `div.uui-layout88_item-2.w-dyn-item`
- Title: `h3.uui-heading-xxsmall-4:not(.w-condition-invisible)` — pick first with non-blank text
- Month: `div.event-month-2`, Day: `div.event-day-2`, Time: `div.event-time-new-2`
- Build date string: `"$month $day $year"` format `"MMM d yyyy"`
- Confidence score: `0.65`

**Test for each scraper** (see Task 9 for full test file):

```rust
#[test]
fn black_cat_parses_fixture() {
    let html = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/black-cat-schedule.html"));
    let events = BlackCatScraper::parse(html).expect("Parse failed");
    assert!(!events.is_empty(), "Should parse ≥1 event");
    let first = &events[0];
    assert!(!first.title.is_empty(), "Title must be non-empty");
    assert_eq!(first.venue_name, "Black Cat");
    // start_time was successfully parsed (not default)
    assert!(first.start_time > time::OffsetDateTime::UNIX_EPOCH);
}
```

**Commit:** `feat: BlackCat, DC9, Rhizome DC, 7 Drum City scrapers`
<!-- END_TASK_5 -->

<!-- START_TASK_6 -->
### Task 6: Two-page scrapers (CometPingPong, PieShop, UnionStagePresents)

**Verifies:** rust-port.AC3.1 (for CometPingPong, PieShop, UnionStagePresents)

**Files:**
- Create: `src/adapters/connectors/comet_ping_pong.rs`
- Create: `src/adapters/connectors/pie_shop.rs`
- Create: `src/adapters/connectors/union_stage_presents.rs`

These scrapers make two HTTP requests per event: a listing page to get events + links, then a detail page per event for price/description. For fixture-based tests, provide a `parse_listing(html: &str)` and `parse_detail(html: &str, event: &mut RawEvent)` method split so tests can use the fixture files directly.

**CometPingPong pattern:**

```rust
pub struct CometPingPongScraper { client: Client }

impl CometPingPongScraper {
    const BASE_URL: &'static str = "https://calendar.rediscoverfirebooking.com/cpp-shows";
    const VENUE_NAME: &'static str = "Comet Ping Pong";
    const VENUE_ADDRESS: &'static str = "5037 Connecticut Ave NW, Washington, DC 20008";
    
    /// Parse listing page → partial RawEvents with detail_url
    pub fn parse_listing(html: &str) -> Vec<(RawEvent, String)> {
        // Container: .uui-layout88_item-cpp.w-dyn-item (desktop, excludes mobile)
        // Title: .uui-heading-xxsmall-2
        // Date: .heading-date (format "MMMM d, yyyy")
        // Time: .heading-time
        // Detail link: a.link-block-3[href]
        // Returns tuples of (partial_event, detail_url)
        todo!()
    }
    
    /// Enrich a partial RawEvent with detail page data (price, description)
    pub fn parse_detail(html: &str, event: &mut RawEvent) {
        // Price: .uui-event_tickets-wrapper text
        // Description: .confirm-description
        todo!()
    }
}

#[async_trait]
impl SourceConnector for CometPingPongScraper {
    fn source_id(&self) -> &str { "comet-ping-pong" }
    fn source_type(&self) -> SourceType { SourceType::VenueScraper }
    
    async fn fetch(&self) -> Result<Vec<RawEvent>, IngestionError> {
        let listing_html = self.client.get(Self::BASE_URL).send().await?...text().await?;
        let mut partial_events = Self::parse_listing(&listing_html);
        
        for (event, detail_url) in &mut partial_events {
            // Throttle detail page requests (100ms between requests)
            tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
            if let Ok(detail_html) = self.client.get(&*detail_url).send().await?.text().await {
                Self::parse_detail(&detail_html, event);
            }
        }
        
        Ok(partial_events.into_iter().map(|(e, _)| e).collect())
    }
}
```

**PieShop**: Same two-page pattern. Listing URL: `https://www.pieshopdc.com/shows`. Detail page has `opendate-widget` element with `price` data attribute.

**UnionStagePresents**: Iterates over multiple venue slugs (Union Stage, Jammin Java, Pearl Street Warehouse, Howard Theatre, Miracle Theatre, Capital Turnaround, Nationals Park). Detail page uses `#event-data` element with `data-start`, `data-end`, `data-doors`, `data-price`, `data-image`, `data-ticket-url` attributes. See `UnionStagePresentsScraper.kt` for the complete venue slug → name/address map.

**Fixture-based tests for two-page scrapers:**

```rust
#[test]
fn comet_ping_pong_parses_listing_fixture() {
    let html = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/comet-ping-pong-listing.html"));
    let events = CometPingPongScraper::parse_listing(html);
    assert!(!events.is_empty(), "Should parse ≥1 event from listing");
    let (first, _url) = &events[0];
    assert!(!first.title.is_empty(), "Title must be non-empty");
}

#[test]
fn comet_ping_pong_parses_detail_fixture() {
    let listing_html = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/comet-ping-pong-listing.html"));
    let detail_html = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/comet-ping-pong-detail.html"));
    
    let mut events = CometPingPongScraper::parse_listing(listing_html);
    assert!(!events.is_empty());
    let (mut event, _) = events.remove(0);
    CometPingPongScraper::parse_detail(detail_html, &mut event);
    // Price should be populated from detail page
    // (may or may not be present depending on fixture content)
}

#[test]
fn comet_ping_pong_empty_fixture_returns_no_events() {
    let html = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/comet-ping-pong-empty.html"));
    let events = CometPingPongScraper::parse_listing(html);
    assert!(events.is_empty(), "Empty fixture should yield no events");
}
```

**Commit:** `feat: CometPingPong, PieShop, UnionStagePresents two-page scrapers`
<!-- END_TASK_6 -->

<!-- END_SUBCOMPONENT_B -->

<!-- START_SUBCOMPONENT_C (tasks 7-9) -->

<!-- START_TASK_7 -->
### Task 7: Ingestion orchestrator + admin trigger wiring

**Verifies:** rust-port.AC3.4, rust-port.AC3.5, rust-port.AC3.6, rust-port.AC3.7, rust-port.AC3.8

**Files:**
- Create: `src/ingestion/orchestrator.rs`
- Modify: `src/http/admin.rs` — replace placeholder trigger handlers with real orchestration

**Create src/ingestion/orchestrator.rs:**

```rust
//! Ingestion orchestrator — runs the full fetch → normalize → filter → deduplicate → upsert pipeline
//! for a single source connector.

use std::sync::Arc;

use crate::{
    domain::{
        error::IngestionError,
        event::EventUpsertCommand,
        source::SourceId,
    },
    ingestion::{
        deduplication::DeduplicationService,
        normalization::NormalizationService,
    },
    ports::{
        event_repository::UpsertResult, EventRepository, IngestionRunRepository, SourceConnector,
        SourceRepository,
    },
};

pub struct IngestionStats {
    pub events_fetched: i32,
    pub events_created: i32,
    pub events_updated: i32,
    pub events_deduplicated: i32,
}

pub struct IngestionOrchestrator {
    pub events: Arc<dyn EventRepository>,
    pub ingestion_runs: Arc<dyn IngestionRunRepository>,
    pub sources: Arc<dyn SourceRepository>,
    pub normalization: NormalizationService,
    pub deduplication: DeduplicationService,
}

impl IngestionOrchestrator {
    pub fn new(
        events: Arc<dyn EventRepository>,
        ingestion_runs: Arc<dyn IngestionRunRepository>,
        sources: Arc<dyn SourceRepository>,
    ) -> Self {
        Self {
            events,
            ingestion_runs,
            sources,
            normalization: NormalizationService,
            deduplication: DeduplicationService,
        }
    }

    /// Run the full ingestion pipeline for one connector.
    pub async fn run_connector(
        &self,
        connector: &dyn SourceConnector,
    ) -> Result<IngestionStats, IngestionError> {
        // Find source record (if it exists — log warning if not found, continue anyway)
        let source = self.sources.find_by_name(connector.source_id()).await
            .ok()
            .flatten();
        let source_id = source.as_ref().map(|s| s.id);

        // Create ingestion run record
        let run = if let Some(sid) = source_id {
            // IngestionError::Repo is a From<RepoError> conversion added in Phase 2.
            Some(self.ingestion_runs.create(sid).await?)
        } else {
            tracing::warn!(
                connector = connector.source_id(),
                "No source record found for connector — stats will not be persisted"
            );
            None
        };

        let result = self.run_pipeline(connector, source_id).await;

        // Update run record with outcome
        if let Some(run) = run {
            match &result {
                Ok(stats) => {
                    let _ = self.ingestion_runs.mark_success(
                        run.id,
                        stats.events_fetched,
                        stats.events_created,
                        stats.events_updated,
                        stats.events_deduplicated,
                    ).await;
                    if let Some(sid) = source_id {
                        let _ = self.sources.record_success(sid).await;
                    }
                }
                Err(e) => {
                    let _ = self.ingestion_runs.mark_failed(run.id, &e.to_string()).await;
                    if let Some(sid) = source_id {
                        let _ = self.sources.record_failure(sid, &e.to_string()).await;
                    }
                }
            }
        }

        result
    }

    async fn run_pipeline(
        &self,
        connector: &dyn SourceConnector,
        source_id: Option<crate::domain::source::SourceId>,
    ) -> Result<IngestionStats, IngestionError> {
        // Step 1: Fetch
        let raw_events = connector.fetch().await?;
        let events_fetched = raw_events.len() as i32;
        tracing::info!(connector = connector.source_id(), count = events_fetched, "Fetched events");

        if raw_events.is_empty() {
            return Ok(IngestionStats {
                events_fetched: 0,
                events_created: 0,
                events_updated: 0,
                events_deduplicated: 0,
            });
        }

        // Step 2: Normalize
        let normalized = self.normalization.normalize(raw_events);

        // Step 3: Filter placeholder titles
        let filtered: Vec<_> = normalized
            .into_iter()
            .filter(|e| {
                if NormalizationService::is_placeholder(&e.raw.title) {
                    tracing::debug!(title = %e.raw.title, "Filtering placeholder title");
                    false
                } else {
                    true
                }
            })
            .collect();

        // Step 4: Deduplicate
        let before_dedup = filtered.len();
        let deduped = self.deduplication.deduplicate(filtered);
        let events_deduplicated = (before_dedup - deduped.len()) as i32;

        // Step 5: Upsert each event
        let mut events_created = 0;
        let mut events_updated = 0;

        for deduped_event in deduped {
            use crate::domain::event::AgeRestriction;

            // Map age_restriction string to enum
            let age_restriction = match deduped_event.event.raw.age_restriction.as_deref() {
                Some(s) if s.to_lowercase().contains("18") => AgeRestriction::EighteenPlus,
                Some(s) if s.to_lowercase().contains("21") => AgeRestriction::TwentyOnePlus,
                _ => AgeRestriction::AllAges,
            };

            // Inject source_id into attributions
            let mut sources = deduped_event.sources;
            for s in &mut sources {
                s.source_id = source_id;
            }

            let cmd = EventUpsertCommand {
                slug: deduped_event.event.slug.clone(),
                title: deduped_event.event.raw.title.clone(),
                description: deduped_event.event.raw.description.clone(),
                start_time: deduped_event.event.raw.start_time,
                end_time: deduped_event.event.raw.end_time,
                doors_time: deduped_event.event.raw.doors_time,
                venue_name: deduped_event.event.raw.venue_name.clone(),
                venue_address: deduped_event.event.raw.venue_address.clone(),
                artist_names: deduped_event.event.raw.artist_names
                    .iter()
                    .filter_map(|n| crate::ingestion::normalization::clean_artist_name(n))
                    .collect(),
                min_price: deduped_event.event.raw.min_price,
                max_price: deduped_event.event.raw.max_price,
                price_tier: None,
                ticket_url: deduped_event.event.raw.ticket_url.clone(),
                image_url: deduped_event.event.raw.image_url.clone(),
                age_restriction,
                source_attributions: sources,
            };

            match self.events.upsert(cmd).await {
                Ok(UpsertResult::Created) => events_created += 1,
                Ok(UpsertResult::Updated) => events_updated += 1,
                Err(e) => {
                    tracing::warn!(error = %e, "Event upsert failed — continuing");
                }
            }
        }

        Ok(IngestionStats {
            events_fetched,
            events_created,
            events_updated,
            events_deduplicated,
        })
    }
}
```

**Update src/http/admin.rs admin trigger handlers:**

Replace the placeholder trigger implementations with real orchestration calls:

```rust
pub async fn trigger_all_ingestion(
    State(state): State<AppState>,
) -> Result<Json<serde_json::Value>, ApiError> {
    if !state.config.ingestion_enabled {
        return Err(ApiError::Ingestion(IngestionError::Disabled));
    }

    let orchestrator = state.ingestion_orchestrator
        .as_ref()
        .ok_or_else(|| ApiError::Internal("Orchestrator not configured".into()))?;

    let mut total = IngestionStats { events_fetched: 0, events_created: 0, events_updated: 0, events_deduplicated: 0 };
    for connector in &state.connectors {
        match orchestrator.run_connector(connector.as_ref()).await {
            Ok(stats) => {
                total.events_fetched += stats.events_fetched;
                total.events_created += stats.events_created;
                total.events_updated += stats.events_updated;
                total.events_deduplicated += stats.events_deduplicated;
            }
            Err(e) => tracing::error!(error = %e, "Connector failed during manual trigger"),
        }
    }

    Ok(Json(json!({
        "status": "complete",
        "events_fetched": total.events_fetched,
        "events_created": total.events_created,
        "events_updated": total.events_updated,
        "events_deduplicated": total.events_deduplicated,
    })))
}
```

Add `ingestion_orchestrator: Option<Arc<IngestionOrchestrator>>` and `connectors: Vec<Arc<dyn SourceConnector>>` to `AppState`. These are `None`/empty when `INGESTION_ENABLED=false`.

**After expanding AppState, update tests/support/mod.rs:**

The `test_state()` function in `tests/support/mod.rs` constructs `AppState` directly. Adding new fields breaks it with a struct literal missing fields error. Update the function to include the new fields:

```rust
pub fn test_state() -> districtlive_server::http::AppState {
    // ... existing fields ...
    districtlive_server::http::AppState {
        config,
        venues: Arc::new(EmptyVenueRepository),
        artists: Arc::new(EmptyArtistRepository),
        events: Arc::new(EmptyEventRepository),
        featured: Arc::new(EmptyFeaturedRepository),
        sources: Arc::new(EmptySourceRepository),
        ingestion_runs: Arc::new(EmptyIngestionRunRepository),
        // Phase 5 additions:
        ingestion_orchestrator: None,
        connectors: vec![],
    }
}
```

This keeps all Phase 4 tests passing after the AppState expansion.

**Commit:** `feat: ingestion orchestrator, admin trigger wired to real pipeline`
<!-- END_TASK_7 -->

<!-- START_TASK_8 -->
### Task 8: Ingestion scheduler

**Verifies:** Background scheduling when `INGESTION_ENABLED=true`

**Files:**
- Create: `src/ingestion/scheduler.rs`
- Modify: `src/main.rs` — spawn scheduler after server starts

**Create src/ingestion/scheduler.rs:**

```rust
//! Ingestion scheduler — fires the ingestion pipeline on a cron schedule.

use std::sync::Arc;
use tokio_cron_scheduler::{Job, JobScheduler};

use crate::{config::Config, ingestion::orchestrator::IngestionOrchestrator, ports::SourceConnector};

/// Start the ingestion cron scheduler. Returns immediately; jobs run in background.
///
/// Starts two jobs:
/// 1. API cron (`config.ingestion_api_cron`): Ticketmaster, Bandsintown, Dice.fm
/// 2. Scraper cron (`config.ingestion_scraper_cron`): all venue website scrapers
///
/// No-op if `config.ingestion_enabled` is false.
pub async fn start_ingestion_scheduler(
    config: Arc<Config>,
    orchestrator: Arc<IngestionOrchestrator>,
    api_connectors: Vec<Arc<dyn SourceConnector>>,
    scraper_connectors: Vec<Arc<dyn SourceConnector>>,
) -> anyhow::Result<JobScheduler> {
    let sched = JobScheduler::new().await?;

    // API connectors job
    {
        let orchestrator = orchestrator.clone();
        let connectors = api_connectors.clone();
        let cron = config.ingestion_api_cron.clone();
        sched.add(Job::new_async(&cron, move |_uuid, _l| {
            let orchestrator = orchestrator.clone();
            let connectors = connectors.clone();
            Box::pin(async move {
                tracing::info!("Ingestion scheduler: running API connectors");
                for connector in &connectors {
                    if let Err(e) = orchestrator.run_connector(connector.as_ref()).await {
                        tracing::error!(error = %e, connector = connector.source_id(), "Connector failed");
                    }
                }
            })
        })?).await?;
    }

    // Scraper connectors job
    {
        let orchestrator = orchestrator.clone();
        let connectors = scraper_connectors.clone();
        let cron = config.ingestion_scraper_cron.clone();
        sched.add(Job::new_async(&cron, move |_uuid, _l| {
            let orchestrator = orchestrator.clone();
            let connectors = connectors.clone();
            Box::pin(async move {
                tracing::info!("Ingestion scheduler: running scraper connectors");
                for connector in &connectors {
                    if let Err(e) = orchestrator.run_connector(connector.as_ref()).await {
                        tracing::error!(error = %e, connector = connector.source_id(), "Connector failed");
                    }
                }
            })
        })?).await?;
    }

    sched.start().await?;
    tracing::info!(
        api_cron = %config.ingestion_api_cron,
        scraper_cron = %config.ingestion_scraper_cron,
        "Ingestion scheduler started"
    );
    Ok(sched)
}
```

**Update src/main.rs:**

After starting the HTTP server, conditionally start the ingestion scheduler:

```rust
if config.ingestion_enabled {
    let orchestrator = Arc::new(IngestionOrchestrator::new(
        state.events.clone(),
        state.ingestion_runs.clone(),
        state.sources.clone(),
    ));

    let (api_connectors, scraper_connectors) = build_connectors(&config, &http_client);

    tokio::spawn(async move {
        if let Err(e) = start_ingestion_scheduler(
            config.clone(), orchestrator, api_connectors, scraper_connectors
        ).await {
            tracing::error!(error = %e, "Failed to start ingestion scheduler");
        }
    });
}
```

The `build_connectors(config, client)` function constructs all 10 connector instances and splits them into API (Ticketmaster, Bandsintown, Dice.fm) and scraper (all 7 venue scrapers) groups.

**Commit:** `feat: ingestion scheduler with dual-cron jobs`
<!-- END_TASK_8 -->

<!-- START_TASK_9 -->
### Task 9: Connector fixture tests + normalization property tests

**Verifies:** rust-port.AC3.1, rust-port.AC7.1, rust-port.AC7.2, rust-port.AC7.3

**Files:**
- Create: `tests/connector_tests.rs` — fixture-based tests for all 10 connectors
- Modify: `tests/properties.rs` — add normalization and deduplication property tests
- Modify: `tests/BUILD.bazel` — add `:connector_tests` target

**Step 1: Create tests/connector_tests.rs**

```rust
//! Fixture-based tests for all 10 source connectors.
//!
//! Each test parses the corresponding fixture file and verifies ≥1 RawEvent
//! with non-empty title, venue_name, and valid start_time.
//!
//! Run with: `just test`

use districtlive_server::adapters::connectors::{
    bandsintown::BandsintownConnector,
    black_cat::BlackCatScraper,
    comet_ping_pong::CometPingPongScraper,
    dc9::Dc9Scraper,
    dice_fm::DiceFmConnector,
    pie_shop::PieShopScraper,
    rhizome_dc::RhizomeDcScraper,
    seven_drum_city::SevenDrumCityScraper,
    ticketmaster::TicketmasterConnector,
    union_stage_presents::UnionStagePresentsScraper,
};
use time::OffsetDateTime;

macro_rules! assert_valid_raw_event {
    ($events:expr, $connector_name:expr) => {
        assert!(!$events.is_empty(), "{}: Should parse ≥1 event", $connector_name);
        for event in &$events {
            assert!(!event.title.trim().is_empty(), "{}: title must not be empty", $connector_name);
            assert!(!event.venue_name.trim().is_empty(), "{}: venue_name must not be empty", $connector_name);
            assert!(event.start_time > OffsetDateTime::UNIX_EPOCH, "{}: start_time must be set", $connector_name);
        }
    };
}

// --- AC7.1: All connector fixture tests ---

#[test]
fn ticketmaster_parses_fixture() {
    let json = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/ticketmaster-dc-events.json"));
    let events = TicketmasterConnector::parse_json(json).expect("Parse failed");
    assert_valid_raw_event!(events, "Ticketmaster");
}

#[test]
fn bandsintown_parses_fixture() {
    let json = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/events.json"));
    let events = BandsintownConnector::parse_json(json, "test-artist").expect("Parse failed");
    assert_valid_raw_event!(events, "Bandsintown");
}

#[test]
fn dicefm_parses_fixture_with_events() {
    let html = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/dicefm-venue-events.html"));
    let events = DiceFmConnector::parse_html(html, "test-venue").expect("Parse failed");
    assert_valid_raw_event!(events, "Dice.fm");
}

#[test]
fn dicefm_empty_fixture_returns_no_events() {
    let html = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/dicefm-empty-events.html"));
    let events = DiceFmConnector::parse_html(html, "test-venue").expect("Parse failed");
    assert!(events.is_empty(), "Dice.fm empty fixture should yield no events");
}

#[test]
fn black_cat_parses_fixture() {
    let html = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/black-cat-schedule.html"));
    let events = BlackCatScraper::parse(html).expect("Parse failed");
    assert_valid_raw_event!(events, "BlackCat");
}

#[test]
fn dc9_parses_fixture() {
    let html = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/dc9-events.html"));
    let events = Dc9Scraper::parse(html).expect("Parse failed");
    assert_valid_raw_event!(events, "DC9");
}

#[test]
fn comet_ping_pong_parses_listing_fixture() {
    let html = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/comet-ping-pong-listing.html"));
    let events = CometPingPongScraper::parse_listing(html);
    assert!(!events.is_empty(), "CometPingPong: Should parse ≥1 event");
    for (event, _) in &events {
        assert!(!event.title.trim().is_empty(), "Title must not be empty");
        assert!(!event.venue_name.trim().is_empty(), "Venue must not be empty");
    }
}

#[test]
fn pie_shop_parses_listing_fixture() {
    let html = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/pie-shop-listing.html"));
    let events = PieShopScraper::parse_listing(html);
    assert!(!events.is_empty(), "PieShop: Should parse ≥1 event");
}

#[test]
fn rhizome_dc_parses_fixture() {
    let html = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/rhizome-dc-events.html"));
    let events = RhizomeDcScraper::parse(html).expect("Parse failed");
    assert_valid_raw_event!(events, "RhizomeDC");
}

#[test]
fn seven_drum_city_parses_fixture() {
    let html = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/7-drum-city-events.html"));
    let events = SevenDrumCityScraper::parse(html).expect("Parse failed");
    assert_valid_raw_event!(events, "7DrumCity");
}

#[test]
fn union_stage_presents_parses_listing_fixture() {
    let html = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/union-stage-presents-listing.html"));
    let events = UnionStagePresentsScraper::parse_listing(html, "union-stage");
    assert!(!events.is_empty(), "UnionStagePresents: Should parse ≥1 event");
}
```

**Step 2: Add normalization + deduplication property tests to tests/properties.rs**

```rust
use districtlive_server::ingestion::{
    deduplication::DeduplicationService,
    normalization::{generate_slug, NormalizationService, slugify},
};
use districtlive_server::domain::event::RawEvent;
use proptest::prelude::*;
use rust_decimal::Decimal;
use time::OffsetDateTime;

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
```

**Step 3: Add connector_tests target to tests/BUILD.bazel**

```python
rust_test(
    name = "connector_tests",
    srcs = ["connector_tests.rs", "support/mod.rs"],
    crate_root = "connector_tests.rs",
    edition = "2021",
    data = glob(["fixtures/**"]),
    rustc_env = {"CARGO_MANIFEST_DIR": ".", "SQLX_OFFLINE": "true"},
    deps = [
        "//:lib",
        "@crates//:rust_decimal",
        "@crates//:time",
    ],
)
```

Note: `data = glob(["fixtures/**"])` makes fixture files available in the Bazel sandbox. `CARGO_MANIFEST_DIR = "."` is an approximation — in Bazel's sandbox, the execroot working directory is the workspace root. This should work for `include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/..."))` patterns because Bazel puts data files relative to the execroot. **Verify this works with `bazel test //tests:connector_tests` before considering Phase 5 done.** If paths fail to resolve, the fix is to use `$TEST_SRCDIR` instead or change the fixture loading to use `std::fs::read_to_string` with a path from `std::env::var("CARGO_MANIFEST_DIR")` at runtime rather than `include_str!` at compile time.

**Step 4: Run all tests**

```bash
just test
```

Expected: All connector fixture tests pass. All property tests pass.

**Commit:** `test: connector fixture tests, normalization + deduplication property tests`
<!-- END_TASK_9 -->

<!-- END_SUBCOMPONENT_C -->

<!-- START_TASK_10 -->
### Task 10: Final Phase 5 verification

**Step 1: Run full check**

```bash
just check
```

Expected: No clippy warnings (fix any `unused_import`, `dead_code`, or `clippy::format_collect` issues).

**Step 2: Run all tests**

```bash
just test
```

Expected: All tests pass including:
- 10+ connector fixture tests
- Normalization property tests (slug non-empty, URL-safe, start_time preserved)
- Deduplication idempotency test
- Phase 1–4 tests still pass

**Step 3: Manual smoke test (if INGESTION_ENABLED=true in dev environment)**

```bash
curl -u admin:changeme -X POST http://localhost:8080/api/admin/ingest/trigger
```

Expected: Returns JSON with `status: "complete"` and event counts.

**Commit:** `chore: phase 5 verification — just check and just test passing`
<!-- END_TASK_10 -->
