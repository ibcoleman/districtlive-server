CREATE TABLE IF NOT EXISTS featured_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id    UUID NOT NULL REFERENCES events(id),
    blurb       TEXT NOT NULL,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by  VARCHAR(255) NOT NULL DEFAULT 'admin'
);

CREATE INDEX IF NOT EXISTS idx_featured_events_created_at ON featured_events (created_at DESC);
