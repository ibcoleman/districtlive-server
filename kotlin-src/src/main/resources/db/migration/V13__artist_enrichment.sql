-- V13: Async artist enrichment pipeline schema additions
-- Adds enrichment state machine columns to artists and structured title fields to events.

-- Artist enrichment state machine
ALTER TABLE artists
    ADD COLUMN IF NOT EXISTS enrichment_status     VARCHAR(20)               NOT NULL DEFAULT 'PENDING',
    ADD COLUMN IF NOT EXISTS enrichment_attempts   INTEGER                   NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_enriched_at      TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS musicbrainz_id        VARCHAR(36),
    ADD COLUMN IF NOT EXISTS spotify_id            VARCHAR(62),
    ADD COLUMN IF NOT EXISTS canonical_name        VARCHAR(500),
    ADD COLUMN IF NOT EXISTS mb_tags               TEXT[]                    NOT NULL DEFAULT ARRAY[]::TEXT[],
    ADD COLUMN IF NOT EXISTS spotify_genres        TEXT[]                    NOT NULL DEFAULT ARRAY[]::TEXT[],
    ADD COLUMN IF NOT EXISTS image_url             TEXT;

-- Partial index for efficient PENDING artist queries (the hot path for enrichment polling)
CREATE INDEX IF NOT EXISTS idx_artists_enrichment_status_pending
    ON artists (enrichment_status)
    WHERE enrichment_status = 'PENDING';

-- Event title parsing fields (for future Ollama EventTitleParser)
ALTER TABLE events
    ADD COLUMN IF NOT EXISTS title_parsed BOOLEAN     NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS event_type   VARCHAR(50);
