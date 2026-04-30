-- Align column types with Rust domain: SourceType is declared as `text` in
-- src/domain/source.rs (`#[sqlx(type_name = "text", ...)]`), but the columns
-- were created as VARCHAR(50). sqlx 0.8 enforces strict type-name matching
-- on decode, so reads fail with "mismatched types ... is not compatible with
-- SQL type VARCHAR".

ALTER TABLE sources         ALTER COLUMN source_type TYPE TEXT;
ALTER TABLE event_sources   ALTER COLUMN source_type TYPE TEXT;
