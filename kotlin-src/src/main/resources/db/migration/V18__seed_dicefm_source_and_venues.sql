-- V18__seed_dicefm_source_and_venues.sql
--
-- Seeds the Dice.fm connector source record and four DC venues that are only
-- listed on Dice.fm (not already in the DB from V8 or V11).
--
-- Venues already in DB (not seeded here): Songbyrd (V8), DC9 (V8), Comet Ping Pong (V8).
-- Venues new to DB (seeded here): Byrdland, BERHTA, The Arlo, Secret Location DC.
--
-- Source type: DICE_FM (new enum value added in this release)
-- Venue UUIDs: deterministic via uuid_generate_v5 (pattern from V14)

-- Seed Dice.fm source record
INSERT INTO sources (name, source_type, configuration, scrape_schedule) VALUES
    ('dicefm', 'DICE_FM', '{"url": "https://dice.fm/"}', '0 0 3 * * *')
ON CONFLICT (name) DO NOTHING;

-- Seed the four Dice.fm-exclusive venues with deterministic UUIDs
INSERT INTO venues (id, name, slug, address, neighborhood, capacity, venue_type, website_url) VALUES
    (
        uuid_generate_v5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'districtlive.venue.byrdland'),
        'Byrdland',
        'byrdland',
        '3917 Georgia Ave NW, Washington, DC 20011',
        'Petworth',
        NULL,
        'club',
        'https://dice.fm/venue/byrdland-wo3n'
    ),
    (
        uuid_generate_v5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'districtlive.venue.berhta'),
        'BERHTA',
        'berhta',
        NULL,
        'Washington, DC',
        NULL,
        'club',
        'https://dice.fm/venue/berhta-8emn5'
    ),
    (
        uuid_generate_v5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'districtlive.venue.the-arlo'),
        'The Arlo',
        'the-arlo',
        '901 N St NW, Washington, DC 20001',
        'Shaw',
        NULL,
        'venue',
        'https://dice.fm/venue/the-arlo-washington-dc-2w997'
    ),
    (
        uuid_generate_v5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'districtlive.venue.secret-location-dc'),
        'Secret Location DC',
        'secret-location-dc',
        NULL,
        'Washington, DC',
        NULL,
        'venue',
        'https://dice.fm/venue/secret-location---dc-xeex3'
    )
ON CONFLICT (slug) DO NOTHING;
