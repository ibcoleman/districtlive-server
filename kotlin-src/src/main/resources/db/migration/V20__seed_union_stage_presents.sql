-- V20__seed_union_stage_presents.sql
--
-- Seeds the Union Stage Presents scraper source record and four venues not
-- already in the DB. Three USP venues are already seeded:
--   - Union Stage (V8, slug: union-stage)
--   - Pearl Street Warehouse (V8, slug: pearl-street-warehouse)
--   - The Howard Theatre (V8, slug: howard-theatre)
--
-- New venues: Jammin Java, Miracle Theatre, Capital Turnaround, Nationals Park.
-- Source name must exactly match UnionStagePresentsScraper.sourceId.

-- Seed Union Stage Presents source record
INSERT INTO sources (name, source_type, configuration, scrape_schedule)
VALUES ('union-stage-presents', 'VENUE_SCRAPER', '{"url": "https://unionstagepresents.com"}', '0 0 3 * * *')
ON CONFLICT (name) DO NOTHING;

-- Seed the four USP-exclusive venues with deterministic UUIDs (V14/V18 pattern)
INSERT INTO venues (id, name, slug, address, neighborhood, capacity, venue_type, website_url) VALUES
    (
        uuid_generate_v5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'districtlive.venue.jammin-java'),
        'Jammin Java',
        'jammin-java',
        '227 Maple Ave E, Vienna, VA 22180',
        'Vienna',
        200,
        'club',
        'https://unionstagepresents.com/jammin-java'
    ),
    (
        uuid_generate_v5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'districtlive.venue.miracle-theatre'),
        'Miracle Theatre',
        'miracle-theatre',
        '535 8th St SE, Washington, DC 20003',
        'Capitol Hill',
        300,
        'venue',
        'https://unionstagepresents.com/miracle-theatre'
    ),
    (
        uuid_generate_v5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'districtlive.venue.capital-turnaround'),
        'Capital Turnaround',
        'capital-turnaround',
        '70 N St SE, Washington, DC 20003',
        'Navy Yard',
        NULL,
        'venue',
        'https://unionstagepresents.com/capital-turnaround'
    ),
    (
        uuid_generate_v5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'districtlive.venue.nationals-park'),
        'Nationals Park',
        'nationals-park',
        '1500 S Capitol St SE, Washington, DC 20003',
        'Navy Yard',
        41339,
        'stadium',
        'https://www.mlb.com/nationals/ballpark'
    )
ON CONFLICT (slug) DO NOTHING;
