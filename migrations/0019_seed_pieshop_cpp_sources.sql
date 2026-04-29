-- V19__seed_pieshop_cpp_sources.sql
--
-- Seeds source records for Pie Shop and Comet Ping Pong venue scrapers.
-- Both venues are already seeded in V8 — no venue seeding needed here.
--
-- Source IDs use kebab-case to match codebase convention (black-cat, rhizome-dc, 7-drum-city).
-- The sources.name value must exactly match the sourceId property on the corresponding
-- scraper class, as IngestionOrchestrator matches connectors to DB records by this value.

-- Seed Pie Shop scraper source
INSERT INTO sources (name, source_type, configuration, scrape_schedule)
VALUES ('pie-shop', 'VENUE_SCRAPER', '{"url": "https://www.pieshopdc.com/shows"}', '0 0 3 * * *')
ON CONFLICT (name) DO NOTHING;

-- Seed Comet Ping Pong scraper source
INSERT INTO sources (name, source_type, configuration, scrape_schedule)
VALUES ('comet-ping-pong', 'VENUE_SCRAPER', '{"url": "https://calendar.rediscoverfirebooking.com/cpp-shows"}', '0 0 3 * * *')
ON CONFLICT (name) DO NOTHING;
