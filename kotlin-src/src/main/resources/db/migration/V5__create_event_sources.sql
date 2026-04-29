CREATE TABLE IF NOT EXISTS event_sources (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id          UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    source_type       VARCHAR(50) NOT NULL,
    source_identifier VARCHAR(500),
    source_url        VARCHAR(500),
    last_scraped_at   TIMESTAMP WITH TIME ZONE,
    confidence_score  NUMERIC(3, 2) DEFAULT 0.50,
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_event_sources_event_id ON event_sources(event_id);
CREATE INDEX IF NOT EXISTS idx_event_sources_source_type ON event_sources(source_type);
