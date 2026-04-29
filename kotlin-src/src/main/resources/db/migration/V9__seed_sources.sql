-- Seed connector source records for ingestion tracking
INSERT INTO sources (name, source_type, configuration, scrape_schedule) VALUES
    ('ticketmaster', 'TICKETMASTER_API', '{"dmaId": 224, "classificationName": "music"}', '0 0 */6 * * *'),
    ('bandsintown', 'BANDSINTOWN_API', '{"region": "DC"}', '0 0 */6 * * *'),
    ('black-cat', 'VENUE_SCRAPER', '{"url": "https://www.blackcatdc.com/schedule.html"}', '0 0 3 * * *'),
    ('rhizome-dc', 'VENUE_SCRAPER', '{"url": "https://www.rhizomedc.org/new-events"}', '0 0 3 * * *'),
    ('7-drum-city', 'VENUE_SCRAPER', '{"url": "https://thepocket.7drumcity.com"}', '0 0 3 * * *')
ON CONFLICT (name) DO NOTHING;
