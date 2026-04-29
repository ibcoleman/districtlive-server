CREATE TABLE IF NOT EXISTS artists (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          VARCHAR(255) NOT NULL,
    slug          VARCHAR(255) NOT NULL UNIQUE,
    genres        TEXT[],
    is_local      BOOLEAN DEFAULT false,
    spotify_url   VARCHAR(500),
    bandcamp_url  VARCHAR(500),
    instagram_url VARCHAR(500),
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at    TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_artists_slug ON artists(slug);
CREATE INDEX IF NOT EXISTS idx_artists_name ON artists(name);
