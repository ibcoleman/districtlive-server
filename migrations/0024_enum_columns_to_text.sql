-- Same shape as 0023 (source_type), now sweeping the rest of the
-- enum-backed columns. Each Rust domain enum uses
-- `#[sqlx(type_name = "text", rename_all = "SCREAMING_SNAKE_CASE")]`,
-- but the original migrations created the columns as VARCHAR(N).
-- sqlx 0.8 enforces strict type-name matching on decode and rejects them.

ALTER TABLE artists         ALTER COLUMN enrichment_status TYPE TEXT;
ALTER TABLE ingestion_runs  ALTER COLUMN status            TYPE TEXT;
ALTER TABLE events          ALTER COLUMN status            TYPE TEXT;
ALTER TABLE events          ALTER COLUMN price_tier        TYPE TEXT;
ALTER TABLE events          ALTER COLUMN age_restriction   TYPE TEXT;
ALTER TABLE events          ALTER COLUMN event_type        TYPE TEXT;
