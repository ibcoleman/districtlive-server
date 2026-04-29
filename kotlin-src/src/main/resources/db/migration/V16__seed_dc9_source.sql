-- Seed DC9 Nightclub source record for ingestion tracking
INSERT INTO sources (name, source_type, configuration, scrape_schedule) VALUES
    ('dc9', 'VENUE_SCRAPER', '{"url": "https://dc9.club/"}', '0 0 3 * * *')
ON CONFLICT (name) DO NOTHING;
