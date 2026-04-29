-- V15__venue_display_overrides.sql
--
-- Add nullable display override columns to venues.
-- When set, these values are used in API responses instead of the source name/slug.
-- Source columns remain unchanged for ingestion matching (resolveVenue).

ALTER TABLE venues ADD COLUMN IF NOT EXISTS display_name VARCHAR(255);
ALTER TABLE venues ADD COLUMN IF NOT EXISTS display_slug VARCHAR(255);

-- Apply the Kennedy Center override.
-- Safe no-op if the row doesn't exist yet (UPDATE ... WHERE matches 0 rows).
UPDATE venues
SET display_name = 'The Kennedy Center',
    display_slug = 'the-kennedy-center'
WHERE name = 'Trump Kennedy Center - Concert Hall';
