-- V14__deterministic_venue_uuids.sql
--
-- Convert venue UUIDs to deterministic UUID v5 values derived from each venue's slug.
--
-- Problem: V8/V11 seed migrations use gen_random_uuid(), so every DB reset produces
-- different venue UUIDs.  The Android client caches venues by UUID; a UUID change means
-- stale rows accumulate in Room alongside the new ones, showing each venue twice.
--
-- Fix: uuid_generate_v5(namespace, 'districtlive.venue.<slug>') is stable — the same
-- slug always produces the same UUID regardless of when or how many times migrations run.
-- The Android deleteAll() backstop handles any residual staleness from old builds.
--
-- Namespace used: DNS (6ba7b810-9dad-11d1-80b4-00c04fd430c8)
-- Name format:    'districtlive.venue.<slug>'

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Re-add the events→venues FK with ON UPDATE CASCADE so that updating venues.id
-- automatically propagates to events.venue_id without manual coordination.
ALTER TABLE events DROP CONSTRAINT IF EXISTS events_venue_id_fkey;
ALTER TABLE events ADD CONSTRAINT events_venue_id_fkey
    FOREIGN KEY (venue_id) REFERENCES venues(id)
    ON UPDATE CASCADE;

-- Rewrite all venue PKs to deterministic values.
-- events.venue_id cascades automatically.
UPDATE venues
SET id = uuid_generate_v5(
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
    'districtlive.venue.' || slug
);
