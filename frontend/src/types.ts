import type { Tagged } from 'type-fest';

// --- Nominal ID types ---
export type EventId = Tagged<string, 'EventId'>;
export type VenueId = Tagged<string, 'VenueId'>;
export type ArtistId = Tagged<string, 'ArtistId'>;
export type SourceId = Tagged<string, 'SourceId'>;
export type FeaturedEventId = Tagged<string, 'FeaturedEventId'>;
export type IngestionRunId = Tagged<string, 'IngestionRunId'>;

// --- String literal union types for enums ---
export type EventStatus = 'Active' | 'Cancelled' | 'Postponed' | 'Rescheduled';
export type SourceType = 'TicketmasterApi' | 'BandsintownApi' | 'VenueScraper' | 'Manual' | 'DiceFm';
export type IngestionRunStatus = 'Running' | 'Success' | 'Failed';
export type PriceTier = 'Free' | 'Under15' | 'Price15To30' | 'Over30';
export type AgeRestriction = 'AllAges' | 'EighteenPlus' | 'TwentyOnePlus';

// --- API response types (match JSON shapes from Phase 4 DTOs) ---

export type VenueDto = {
  readonly id: VenueId;
  readonly name: string;
  readonly slug: string;
  readonly neighborhood: string | null;
  readonly website_url: string | null;
  readonly upcoming_event_count: number;
};

export type ArtistDto = {
  readonly id: ArtistId;
  readonly name: string;
  readonly slug: string;
  readonly genres: Array<string>;
  readonly is_local: boolean;
  readonly canonical_name: string | null;
  readonly image_url: string | null;
};

export type EventDto = {
  readonly id: EventId;
  readonly title: string;
  readonly slug: string;
  readonly start_time: string; // ISO8601
  readonly doors_time: string | null;
  readonly venue: VenueDto | null;
  readonly artists: Array<ArtistDto>;
  readonly min_price: string | null; // Decimal serialized as string
  readonly max_price: string | null;
  readonly price_tier: PriceTier | null;
  readonly ticket_url: string | null;
  readonly sold_out: boolean;
  readonly image_url: string | null;
  readonly age_restriction: AgeRestriction;
  readonly status: EventStatus;
  readonly created_at: string; // ISO8601
};

export type EventDetailDto = EventDto & {
  readonly description: string | null;
  readonly end_time: string | null;
  readonly sources: Array<EventSourceDto>;
  readonly related_events: Array<EventDto>;
};

export type EventSourceDto = {
  readonly source_type: SourceType;
  readonly last_scraped_at: string | null;
};

export type FeaturedEventDto = {
  readonly id: FeaturedEventId;
  readonly event: EventDetailDto;
  readonly blurb: string;
  readonly created_at: string;
  readonly created_by: string;
};

export type SourceHealthDto = {
  readonly id: SourceId;
  readonly name: string;
  readonly source_type: SourceType;
  readonly last_success_at: string | null;
  readonly last_failure_at: string | null;
  readonly consecutive_failures: number;
  readonly healthy: boolean;
};

export type IngestionRunDto = {
  readonly id: IngestionRunId;
  readonly source_id: SourceId;
  readonly status: IngestionRunStatus;
  readonly events_fetched: number;
  readonly events_created: number;
  readonly events_updated: number;
  readonly events_deduplicated: number;
  readonly error_message: string | null;
  readonly started_at: string;
  readonly completed_at: string | null;
};

export type PageDto<T> = {
  readonly items: Array<T>;
  readonly total: number;
  readonly page: number;
  readonly per_page: number;
};
