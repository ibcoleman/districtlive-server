import { ResultAsync } from 'neverthrow';
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
