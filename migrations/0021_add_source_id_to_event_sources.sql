ALTER TABLE event_sources ADD COLUMN source_id UUID REFERENCES sources(id);
