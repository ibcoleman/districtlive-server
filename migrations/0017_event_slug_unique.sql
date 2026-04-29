-- V17__event_slug_unique.sql
-- Step 1: Remove orphaned event_sources for events that will be deleted
DELETE FROM event_sources
WHERE event_id IN (
    SELECT e.id
    FROM events e
    INNER JOIN (
        SELECT slug, MAX(updated_at) AS max_updated
        FROM events
        GROUP BY slug
        HAVING COUNT(*) > 1
    ) dupes ON e.slug = dupes.slug AND e.updated_at < dupes.max_updated
);

-- Step 2: Remove featured_events referencing events that will be deleted
DELETE FROM featured_events
WHERE event_id IN (
    SELECT e.id
    FROM events e
    INNER JOIN (
        SELECT slug, MAX(updated_at) AS max_updated
        FROM events
        GROUP BY slug
        HAVING COUNT(*) > 1
    ) dupes ON e.slug = dupes.slug AND e.updated_at < dupes.max_updated
);

-- Step 3: Remove orphaned event_artists for events that will be deleted
DELETE FROM event_artists
WHERE event_id IN (
    SELECT e.id
    FROM events e
    INNER JOIN (
        SELECT slug, MAX(updated_at) AS max_updated
        FROM events
        GROUP BY slug
        HAVING COUNT(*) > 1
    ) dupes ON e.slug = dupes.slug AND e.updated_at < dupes.max_updated
);

-- Step 4: Delete duplicate events (keep the most recently updated per slug)
DELETE FROM events
WHERE id IN (
    SELECT e.id
    FROM events e
    INNER JOIN (
        SELECT slug, MAX(updated_at) AS max_updated
        FROM events
        GROUP BY slug
        HAVING COUNT(*) > 1
    ) dupes ON e.slug = dupes.slug AND e.updated_at < dupes.max_updated
);

-- Step 5: Add UNIQUE constraint on events.slug
-- The existing index idx_events_slug (non-unique) is replaced by the unique constraint's implicit index
DROP INDEX IF EXISTS idx_events_slug;
ALTER TABLE events ADD CONSTRAINT uq_events_slug UNIQUE (slug);

-- Step 6: Reset all sources to healthy state
UPDATE sources SET consecutive_failures = 0, healthy = true, updated_at = now();
