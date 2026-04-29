CREATE TABLE IF NOT EXISTS events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           VARCHAR(500) NOT NULL,
    slug            VARCHAR(500) NOT NULL,
    description     TEXT,
    start_time      TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time        TIMESTAMP WITH TIME ZONE,
    doors_time      TIMESTAMP WITH TIME ZONE,
    min_price       NUMERIC(10, 2),
    max_price       NUMERIC(10, 2),
    price_tier      VARCHAR(20),
    ticket_url      VARCHAR(500),
    on_sale_date    TIMESTAMP WITH TIME ZONE,
    sold_out        BOOLEAN DEFAULT false,
    ticket_platform VARCHAR(100),
    image_url       VARCHAR(500),
    age_restriction VARCHAR(20) DEFAULT 'ALL_AGES',
    status          VARCHAR(20) DEFAULT 'ACTIVE',
    venue_id        UUID REFERENCES venues(id),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS event_artists (
    event_id  UUID REFERENCES events(id) ON DELETE CASCADE,
    artist_id UUID REFERENCES artists(id) ON DELETE CASCADE,
    PRIMARY KEY (event_id, artist_id)
);

CREATE INDEX IF NOT EXISTS idx_events_slug ON events(slug);
CREATE INDEX IF NOT EXISTS idx_events_start_time ON events(start_time);
CREATE INDEX IF NOT EXISTS idx_events_venue_id ON events(venue_id);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_price_tier ON events(price_tier);
