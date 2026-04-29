CREATE TABLE IF NOT EXISTS venues (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(255) NOT NULL,
    slug        VARCHAR(255) NOT NULL UNIQUE,
    address     VARCHAR(500),
    neighborhood VARCHAR(100),
    capacity    INTEGER,
    venue_type  VARCHAR(50),
    website_url VARCHAR(500),
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_venues_slug ON venues(slug);
CREATE INDEX IF NOT EXISTS idx_venues_neighborhood ON venues(neighborhood);
