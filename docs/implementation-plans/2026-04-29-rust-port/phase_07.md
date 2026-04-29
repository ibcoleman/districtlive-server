# DistrictLive Rust Port — Phase 7: Frontend

**Goal:** The two admin pages are available in the Rust frontend — an ingestion monitor and a featured events manager — served via rust-embed alongside the existing public frontend.

**Architecture:** Multi-entry Vite build with three entry points: root `index.html`, `src/pages/ingestion/index.html`, and `src/pages/featured/index.html`. A shared `ApiClient` handles Basic auth credential storage in sessionStorage and header injection. Two new Axum routes serve the admin HTML pages. No hot reload — only `pnpm build` + `just check`.

**Tech Stack:** TypeScript 5.5, Vite 6, neverthrow 8, type-fest 5, `btoa()` for Base64 auth header, rust-embed for static asset serving

**Scope:** Phase 7 of 7 from original design

**Codebase verified:** 2026-04-29

---

## Acceptance Criteria Coverage

### rust-port.AC6: Frontend pages
- **rust-port.AC6.1 Success:** `pnpm build` in `frontend/` produces bundles for ingestion monitor and featured events pages without TypeScript errors
- **rust-port.AC6.2 Success:** The ingestion monitor page renders source health cards populated from `GET /api/admin/sources`
- **rust-port.AC6.3 Success:** Clicking a manual trigger button calls the ingest endpoint and updates the displayed source status
- **rust-port.AC6.4 Success:** The featured events page renders the history list and successfully submits the create-featured form

---

<!-- START_SUBCOMPONENT_A (tasks 1-2) -->

<!-- START_TASK_1 -->
### Task 1: Clean up example frontend code + update shared modules

**Verifies:** None (infrastructure — clears the way for new pages)

**Files:**
- Modify: `frontend/src/api.ts` — replace example Note API with `ApiClient` class
- Modify: `frontend/src/types.ts` — replace Note types with DistrictLive DTO types
- Modify: `frontend/src/main.ts` — strip Notes example blocks

**Step 1: Replace frontend/src/types.ts**

Read the current file. Strip all Note-related types and replace with DistrictLive types.

```typescript
// frontend/src/types.ts
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
export type SourceType = 'TicketmasterApi' | 'BandsinTownApi' | 'VenueScraper' | 'Manual' | 'DiceFm';
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
```

**Step 2: Replace frontend/src/api.ts**

Read the current file. Replace with a shared `ApiClient` class using sessionStorage for credentials.

```typescript
// frontend/src/api.ts
import { ResultAsync, errAsync, okAsync } from 'neverthrow';
import type {
  EventDetailDto,
  EventDto,
  FeaturedEventDto,
  IngestionRunDto,
  PageDto,
  SourceHealthDto,
} from './types';

// --- Error types ---

export type ApiError =
  | { type: 'unauthorized'; message: string }
  | { type: 'not_found'; message: string }
  | { type: 'bad_request'; message: string }
  | { type: 'server_error'; message: string }
  | { type: 'network_error'; message: string };

// --- Credential storage ---

const CREDENTIALS_KEY = 'districtlive_admin_auth';

export function storeCredentials(username: string, password: string): void {
  sessionStorage.setItem(CREDENTIALS_KEY, btoa(`${username}:${password}`));
}

export function clearCredentials(): void {
  sessionStorage.removeItem(CREDENTIALS_KEY);
}

function getAuthHeader(): string | null {
  const encoded = sessionStorage.getItem(CREDENTIALS_KEY);
  if (encoded === null) return null;
  return `Basic ${encoded}`;
}

// --- Core request helper ---

async function request<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> | undefined ?? {}),
  };

  const authHeader = getAuthHeader();
  if (authHeader !== null) {
    headers['Authorization'] = authHeader;
  }

  const response = await fetch(path, { ...options, headers });

  if (!response.ok) {
    const body = await response.text().catch(() => '');
    throw new RequestError(response.status, body);
  }

  return response.json() as T;
}

class RequestError extends Error {
  constructor(
    public readonly status: number,
    public readonly body: string,
  ) {
    super(`HTTP ${status}`);
  }
}

function toApiError(e: unknown): ApiError {
  if (e instanceof RequestError) {
    switch (e.status) {
      case 401: return { type: 'unauthorized', message: 'Authentication required' };
      case 404: return { type: 'not_found', message: 'Not found' };
      case 400: return { type: 'bad_request', message: e.body || 'Bad request' };
      default: return { type: 'server_error', message: `Server error: ${e.status}` };
    }
  }
  return { type: 'network_error', message: String(e) };
}

function apiCall<T>(promise: Promise<T>): ResultAsync<T, ApiError> {
  return ResultAsync.fromPromise(promise, toApiError);
}

// --- Public API ---

export function getEvents(params: Record<string, string> = {}): ResultAsync<PageDto<EventDto>, ApiError> {
  const query = new URLSearchParams(params).toString();
  return apiCall(request(`/api/events${query ? `?${query}` : ''}`));
}

export function getEvent(id: string): ResultAsync<EventDetailDto, ApiError> {
  return apiCall(request(`/api/events/${id}`));
}

export function getFeatured(): ResultAsync<FeaturedEventDto, ApiError> {
  return apiCall(request('/api/featured'));
}

// --- Admin API (requires credentials) ---

export function getAdminSources(): ResultAsync<Array<SourceHealthDto>, ApiError> {
  return apiCall(request('/api/admin/sources'));
}

export function getSourceHistory(sourceId: string): ResultAsync<Array<IngestionRunDto>, ApiError> {
  return apiCall(request(`/api/admin/sources/${sourceId}/history`));
}

export function triggerIngestion(): ResultAsync<unknown, ApiError> {
  return apiCall(request('/api/admin/ingest/trigger', { method: 'POST' }));
}

export function triggerSourceIngestion(sourceId: string): ResultAsync<unknown, ApiError> {
  return apiCall(request(`/api/admin/ingest/trigger/${sourceId}`, { method: 'POST' }));
}

export function getFeaturedHistory(): ResultAsync<Array<FeaturedEventDto>, ApiError> {
  return apiCall(request('/api/admin/featured/history'));
}

export function createFeatured(eventId: string, blurb: string): ResultAsync<FeaturedEventDto, ApiError> {
  return apiCall(
    request('/api/admin/featured', {
      method: 'POST',
      body: JSON.stringify({ event_id: eventId, blurb }),
    }),
  );
}
```

**Step 3: Strip Notes example from frontend/src/main.ts**

