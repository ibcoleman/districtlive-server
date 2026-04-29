CREATE TABLE IF NOT EXISTS ingestion_runs (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id               UUID NOT NULL REFERENCES sources(id),
    status                  VARCHAR(20) NOT NULL DEFAULT 'RUNNING',
    events_fetched          INTEGER DEFAULT 0,
    events_created          INTEGER DEFAULT 0,
    events_updated          INTEGER DEFAULT 0,
    events_deduplicated     INTEGER DEFAULT 0,
    error_message           TEXT,
    started_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    completed_at            TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_ingestion_runs_source_id ON ingestion_runs(source_id);
CREATE INDEX IF NOT EXISTS idx_ingestion_runs_started_at ON ingestion_runs(started_at);
