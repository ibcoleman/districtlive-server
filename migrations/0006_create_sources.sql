CREATE TABLE IF NOT EXISTS sources (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                  VARCHAR(255) NOT NULL UNIQUE,
    source_type           VARCHAR(50) NOT NULL,
    configuration         JSONB,
    scrape_schedule       VARCHAR(100),
    last_success_at       TIMESTAMP WITH TIME ZONE,
    last_failure_at       TIMESTAMP WITH TIME ZONE,
    consecutive_failures  INTEGER DEFAULT 0,
    healthy               BOOLEAN DEFAULT true,
    created_at            TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at            TIMESTAMP WITH TIME ZONE DEFAULT now()
);
