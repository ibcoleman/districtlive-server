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

Read `frontend/src/main.ts`. Remove the Notes CRUD section (marked with `@EXAMPLE-BLOCK-START notes` / `@EXAMPLE-BLOCK-END notes`). The greeter section may remain or be simplified. The file can be minimal — the public frontend entry point is separate from the admin pages.

**Step 4: Verify TypeScript compiles**

```bash
cd frontend && npx tsc --noEmit
```

Expected: No errors.

**Commit:** `feat: DistrictLive types, ApiClient with Basic auth, strip example frontend code`
<!-- END_TASK_1 -->

<!-- START_TASK_2 -->
### Task 2: Vite multi-entry configuration + directory structure

**Verifies:** rust-port.AC6.1 (pnpm build produces bundles for all three pages)

**Files:**
- Modify: `frontend/vite.config.ts` — add multi-entry rollupOptions
- Create: `frontend/src/pages/ingestion/` directory
- Create: `frontend/src/pages/featured/` directory

**Step 1: Update frontend/vite.config.ts**

Read the current file. Update to add multi-entry configuration:

```typescript
import { defineConfig } from 'vite';
import { resolve } from 'node:path';

export default defineConfig({
  build: {
    rollupOptions: {
      input: {
        // Public frontend entry (existing)
        main: resolve(import.meta.dirname, 'index.html'),
        // Admin page entries (new)
        ingestion: resolve(import.meta.dirname, 'src/pages/ingestion/index.html'),
        featured: resolve(import.meta.dirname, 'src/pages/featured/index.html'),
      },
      output: {
        // Keep deterministic asset names for rust-embed stability
        entryFileNames: 'assets/[name].[hash].js',
        chunkFileNames: 'assets/[name].[hash].js',
        assetFileNames: 'assets/[name].[hash][extname]',
      },
    },
  },
});
```

**Note:** Vite preserves relative paths from the project root in the output. The admin HTML pages will be at `dist/src/pages/ingestion/index.html` and `dist/src/pages/featured/index.html` in the output.

**Step 2: Create stub page directories**

```bash
mkdir -p frontend/src/pages/ingestion frontend/src/pages/featured
```

These HTML files will be created in Tasks 3 and 4.

**Step 3: Verify config syntax**

```bash
cd frontend && npx vite build --dry-run 2>&1 || echo "Check errors"
```

If `--dry-run` is not available, just run `pnpm build` after Tasks 3 and 4 when the entry HTML files exist.

**Commit:** `chore: Vite multi-entry config for three page builds`
<!-- END_TASK_2 -->

<!-- END_SUBCOMPONENT_A -->

<!-- START_SUBCOMPONENT_B (tasks 3-4) -->

<!-- START_TASK_3 -->
### Task 3: Ingestion monitor page

**Verifies:** rust-port.AC6.2, rust-port.AC6.3

**Files:**
- Create: `frontend/src/pages/ingestion/index.html`
- Create: `frontend/src/pages/ingestion/main.ts`

**Step 1: Create frontend/src/pages/ingestion/index.html**

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>DistrictLive — Ingestion Monitor</title>
    <style>
      body { font-family: system-ui, sans-serif; max-width: 1200px; margin: 0 auto; padding: 1rem; }
      .login-form { max-width: 400px; margin: 4rem auto; padding: 2rem; border: 1px solid #ccc; border-radius: 8px; }
      .login-form h2 { margin-top: 0; }
      .login-form label { display: block; margin-bottom: 0.5rem; font-weight: 500; }
      .login-form input { width: 100%; padding: 0.5rem; margin-bottom: 1rem; box-sizing: border-box; }
      .login-form button { width: 100%; padding: 0.75rem; background: #2563eb; color: white; border: none; border-radius: 4px; cursor: pointer; }
      .error { color: #dc2626; margin-bottom: 1rem; }
      .source-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 1rem; margin-top: 1rem; }
      .source-card { border: 1px solid #e5e7eb; border-radius: 8px; padding: 1rem; }
      .source-card.healthy { border-left: 4px solid #16a34a; }
      .source-card.unhealthy { border-left: 4px solid #dc2626; }
      .source-name { font-weight: 600; font-size: 1.1rem; }
      .source-meta { color: #6b7280; font-size: 0.875rem; margin: 0.5rem 0; }
      .badge { display: inline-block; padding: 0.125rem 0.5rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 500; }
      .badge-green { background: #dcfce7; color: #16a34a; }
      .badge-red { background: #fee2e2; color: #dc2626; }
      .trigger-btn { margin-top: 0.75rem; padding: 0.5rem 1rem; background: #2563eb; color: white; border: none; border-radius: 4px; cursor: pointer; }
      .trigger-btn:disabled { opacity: 0.5; cursor: not-allowed; }
      h1 { display: flex; align-items: center; justify-content: space-between; }
      #trigger-all-btn { padding: 0.5rem 1.25rem; background: #7c3aed; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 0.9rem; }
    </style>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="./main.ts"></script>
  </body>
</html>
```

**Step 2: Create frontend/src/pages/ingestion/main.ts**

```typescript
import { clearCredentials, getAdminSources, getSourceHistory, storeCredentials, triggerIngestion, triggerSourceIngestion } from '../../api';
import type { IngestionRunDto, SourceHealthDto } from '../../types';

// ---- DOM helpers ----

function el(tag: string, attrs: Record<string, string> = {}, ...children: Array<string | Node>): HTMLElement {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    node.setAttribute(k, v);
  }
  for (const child of children) {
    node.append(child);
  }
  return node;
}

// ---- Login form ----

function renderLogin(onLogin: (u: string, p: string) => void, error: string | null): HTMLElement {
  const form = el('div', { class: 'login-form' });
  form.innerHTML = `
    <h2>Admin Login</h2>
    ${error !== null ? `<div class="error">${error}</div>` : ''}
    <label>Username <input id="username" type="text" autocomplete="username" /></label>
    <label>Password <input id="password" type="password" autocomplete="current-password" /></label>
    <button id="login-btn" type="button">Sign in</button>
  `;
  const btn = form.querySelector('#login-btn') as HTMLButtonElement;
  btn.addEventListener('click', () => {
    const u = (form.querySelector('#username') as HTMLInputElement).value;
    const p = (form.querySelector('#password') as HTMLInputElement).value;
    onLogin(u, p);
  });
  return form;
}

// ---- Source health card ----

function renderSourceCard(source: SourceHealthDto, onTrigger: (id: string) => Promise<void>): HTMLElement {
  const card = el('div', { class: `source-card ${source.healthy ? 'healthy' : 'unhealthy'}` });
  const badge = source.healthy
    ? el('span', { class: 'badge badge-green' }, 'Healthy')
    : el('span', { class: 'badge badge-red' }, `${source.consecutive_failures} failures`);

  const lastSuccess = source.last_success_at !== null
    ? new Date(source.last_success_at).toLocaleString()
    : 'Never';

  card.append(
    el('div', { class: 'source-name' }, source.name, ' ', badge),
    el('div', { class: 'source-meta' }, `Type: ${source.source_type}`),
    el('div', { class: 'source-meta' }, `Last success: ${lastSuccess}`),
  );

  const triggerBtn = el('button', { class: 'trigger-btn' }, 'Trigger');
  triggerBtn.addEventListener('click', async () => {
    triggerBtn.setAttribute('disabled', '');
    triggerBtn.textContent = 'Running...';
    await onTrigger(source.id);
    triggerBtn.removeAttribute('disabled');
    triggerBtn.textContent = 'Trigger';
  });
  card.append(triggerBtn);
  return card;
}

// ---- Main app ----

async function renderApp(container: HTMLElement): Promise<void> {
  container.innerHTML = '';

  const heading = el('h1');
  heading.append('Ingestion Monitor');
  const triggerAllBtn = el('button', { id: 'trigger-all-btn' }, 'Trigger All');
  heading.append(triggerAllBtn);
  container.append(heading);

  const status = el('p', {}, 'Loading sources...');
  container.append(status);

  const result = await getAdminSources();
  if (result.isErr()) {
    if (result.error.type === 'unauthorized') {
      clearCredentials();
      init(container);
      return;
    }
    status.textContent = `Error: ${result.error.message}`;
    return;
  }

  status.remove();
  const sources = result.value;
  const grid = el('div', { class: 'source-grid' });

  const onTrigger = async (sourceId: string): Promise<void> => {
    const res = await triggerSourceIngestion(sourceId);
    if (res.isErr()) {
      alert(`Trigger failed: ${res.error.message}`);
    } else {
      await renderApp(container); // Refresh
    }
  };

  for (const source of sources) {
    grid.append(renderSourceCard(source, onTrigger));
  }
  container.append(grid);

  triggerAllBtn.addEventListener('click', async () => {
    triggerAllBtn.setAttribute('disabled', '');
    triggerAllBtn.textContent = 'Triggering...';
    const res = await triggerIngestion();
    triggerAllBtn.removeAttribute('disabled');
    triggerAllBtn.textContent = 'Trigger All';
    if (res.isErr()) {
      alert(`Trigger failed: ${res.error.message}`);
    } else {
      await renderApp(container);
    }
  });
}

function init(container: HTMLElement): void {
  container.innerHTML = '';
  const onLogin = async (username: string, password: string): Promise<void> => {
    storeCredentials(username, password);
    const result = await getAdminSources();
    if (result.isErr() && result.error.type === 'unauthorized') {
      clearCredentials();
      container.innerHTML = '';
      container.append(renderLogin(onLogin, 'Invalid credentials'));
      return;
    }
    await renderApp(container);
  };
  container.append(renderLogin(onLogin, null));
}

const app = document.getElementById('app');
if (app !== null) {
  // Check if we already have credentials stored
  const hasCredentials = sessionStorage.getItem('districtlive_admin_auth') !== null;
  if (hasCredentials) {
    renderApp(app);
  } else {
    init(app);
  }
}
```

**Commit:** `feat: ingestion monitor admin page with source health cards and trigger buttons`
<!-- END_TASK_3 -->

<!-- START_TASK_4 -->
### Task 4: Featured events admin page

**Verifies:** rust-port.AC6.4

**Files:**
- Create: `frontend/src/pages/featured/index.html`
- Create: `frontend/src/pages/featured/main.ts`

**Step 1: Create frontend/src/pages/featured/index.html**

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>DistrictLive — Featured Events</title>
    <style>
      body { font-family: system-ui, sans-serif; max-width: 900px; margin: 0 auto; padding: 1rem; }
      .login-form { max-width: 400px; margin: 4rem auto; padding: 2rem; border: 1px solid #ccc; border-radius: 8px; }
      .login-form h2 { margin-top: 0; }
      .login-form label { display: block; margin-bottom: 0.5rem; font-weight: 500; }
      .login-form input { width: 100%; padding: 0.5rem; margin-bottom: 1rem; box-sizing: border-box; }
      .login-form button { width: 100%; padding: 0.75rem; background: #2563eb; color: white; border: none; border-radius: 4px; cursor: pointer; }
      .error { color: #dc2626; margin-bottom: 1rem; }
      .card { border: 1px solid #e5e7eb; border-radius: 8px; padding: 1rem; margin-bottom: 1rem; }
      .card h3 { margin-top: 0; }
      .create-form { margin-bottom: 2rem; }
      .create-form label { display: block; margin-bottom: 0.5rem; font-weight: 500; }
      .create-form input, .create-form textarea { width: 100%; padding: 0.5rem; margin-bottom: 0.75rem; box-sizing: border-box; }
      .create-form textarea { height: 100px; resize: vertical; }
      .create-form button { padding: 0.5rem 1.25rem; background: #2563eb; color: white; border: none; border-radius: 4px; cursor: pointer; }
      .history-item { padding: 0.75rem; border-bottom: 1px solid #f3f4f6; }
      .history-item:last-child { border-bottom: none; }
      .event-title { font-weight: 600; }
      .event-meta { color: #6b7280; font-size: 0.875rem; }
    </style>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="./main.ts"></script>
  </body>
</html>
```

**Step 2: Create frontend/src/pages/featured/main.ts**

```typescript
import { clearCredentials, createFeatured, getFeaturedHistory, storeCredentials } from '../../api';
import type { FeaturedEventDto } from '../../types';

function el(tag: string, attrs: Record<string, string> = {}, ...children: Array<string | Node>): HTMLElement {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    node.setAttribute(k, v);
  }
  for (const child of children) {
    node.append(child);
  }
  return node;
}

function renderLogin(onLogin: (u: string, p: string) => void, error: string | null): HTMLElement {
  const form = el('div', { class: 'login-form' });
  form.innerHTML = `
    <h2>Admin Login</h2>
    ${error !== null ? `<div class="error">${error}</div>` : ''}
    <label>Username <input id="username" type="text" autocomplete="username" /></label>
    <label>Password <input id="password" type="password" autocomplete="current-password" /></label>
    <button id="login-btn" type="button">Sign in</button>
  `;
  const btn = form.querySelector('#login-btn') as HTMLButtonElement;
  btn.addEventListener('click', () => {
    const u = (form.querySelector('#username') as HTMLInputElement).value;
    const p = (form.querySelector('#password') as HTMLInputElement).value;
    onLogin(u, p);
  });
  return form;
}

function renderFeaturedItem(f: FeaturedEventDto): HTMLElement {
  const div = el('div', { class: 'history-item' });
  div.append(
    el('div', { class: 'event-title' }, f.event.title),
    el('div', { class: 'event-meta' }, `"${f.blurb}"`),
    el('div', { class: 'event-meta' },
      `Added ${new Date(f.created_at).toLocaleDateString()} by ${f.created_by}`),
  );
  return div;
}

async function renderApp(container: HTMLElement): Promise<void> {
  container.innerHTML = '';

  container.append(el('h1', {}, 'Featured Events Admin'));

  // Create form
  const createForm = el('div', { class: 'create-form card' });
  createForm.innerHTML = `
    <h3>Create New Featured Event</h3>
    <label>Event UUID <input id="event-id" type="text" placeholder="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" /></label>
    <label>Editorial blurb <textarea id="blurb" placeholder="Why is this event special?"></textarea></label>
    <div id="create-error" class="error" style="display:none"></div>
    <button id="create-btn" type="button">Create Featured Event</button>
  `;
  container.append(createForm);

  const createBtn = createForm.querySelector('#create-btn') as HTMLButtonElement;
  const createError = createForm.querySelector('#create-error') as HTMLDivElement;

  createBtn.addEventListener('click', async () => {
    const eventId = (createForm.querySelector('#event-id') as HTMLInputElement).value.trim();
    const blurb = (createForm.querySelector('#blurb') as HTMLTextAreaElement).value.trim();

    createError.style.display = 'none';

    if (eventId === '' || blurb === '') {
      createError.textContent = 'Both event UUID and blurb are required.';
      createError.style.display = 'block';
      return;
    }

    createBtn.setAttribute('disabled', '');
    createBtn.textContent = 'Creating...';
    const result = await createFeatured(eventId, blurb);
    createBtn.removeAttribute('disabled');
    createBtn.textContent = 'Create Featured Event';

    if (result.isErr()) {
      createError.textContent = result.error.message;
      createError.style.display = 'block';
    } else {
      await renderApp(container); // Refresh to show new item in history
    }
  });

  // History list
  const historySection = el('div');
  historySection.append(el('h2', {}, 'History'));
  const loadingMsg = el('p', {}, 'Loading history...');
  historySection.append(loadingMsg);
  container.append(historySection);

  const histResult = await getFeaturedHistory();
  loadingMsg.remove();

  if (histResult.isErr()) {
    if (histResult.error.type === 'unauthorized') {
      clearCredentials();
      init(container);
      return;
    }
    historySection.append(el('p', {}, `Error: ${histResult.error.message}`));
    return;
  }

  const history = histResult.value;
  if (history.length === 0) {
    historySection.append(el('p', { class: 'event-meta' }, 'No featured events yet.'));
  } else {
    const list = el('div', { class: 'card' });
    for (const f of history) {
      list.append(renderFeaturedItem(f));
    }
    historySection.append(list);
  }
}

function init(container: HTMLElement): void {
  container.innerHTML = '';
  const onLogin = async (username: string, password: string): Promise<void> => {
    storeCredentials(username, password);
    const result = await getFeaturedHistory();
    if (result.isErr() && result.error.type === 'unauthorized') {
      clearCredentials();
      container.innerHTML = '';
      container.append(renderLogin(onLogin, 'Invalid credentials'));
      return;
    }
    await renderApp(container);
  };
  container.append(renderLogin(onLogin, null));
}

const app = document.getElementById('app');
if (app !== null) {
  const hasCredentials = sessionStorage.getItem('districtlive_admin_auth') !== null;
  if (hasCredentials) {
    renderApp(app);
  } else {
    init(app);
  }
}
```

**Commit:** `feat: featured events admin page with history list and create form`
<!-- END_TASK_4 -->

<!-- END_SUBCOMPONENT_B -->

<!-- START_TASK_5 -->
### Task 5: Wire admin page routes in Rust + pnpm build verification

**Verifies:** rust-port.AC6.1 (pnpm build without TypeScript errors)

**Files:**
- Modify: `src/http/mod.rs` — add routes for admin HTML pages
- Run: `pnpm build` in `frontend/`

**Step 1: Add Axum routes for admin pages**

Read `src/http/mod.rs`. Add two new routes to the public router for the admin HTML pages served from the embedded `frontend/dist/`:

```rust
// In create_router, in the public_router:
.route("/src/pages/ingestion/", get(ingestion_page))
.route("/src/pages/featured/", get(featured_page))
```

Implement the handler functions:

```rust
async fn ingestion_page() -> impl axum::response::IntoResponse {
    serve_html("src/pages/ingestion/index.html")
}

async fn featured_page() -> impl axum::response::IntoResponse {
    serve_html("src/pages/featured/index.html")
}

fn serve_html(path: &str) -> impl axum::response::IntoResponse {
    match Assets::get(path) {
        Some(content) => axum::response::Response::builder()
            .header("Content-Type", "text/html; charset=utf-8")
            .body(axum::body::Body::from(content.data))
            .unwrap_or_else(|_| axum::response::Response::default()),
        None => axum::response::Response::builder()
            .status(axum::http::StatusCode::NOT_FOUND)
            .body(axum::body::Body::from("Page not found"))
            .unwrap_or_default(),
    }
}
```

Note: The `Assets` struct from `rust-embed` is already defined in `mod.rs`. The path `"src/pages/ingestion/index.html"` corresponds to the relative path within `frontend/dist/`.

**Step 2: Run pnpm build**

```bash
cd /workspaces/districtlive-server/frontend && pnpm build
```

Expected:
- No TypeScript errors
- `dist/` directory updated with:
  - `dist/index.html` (root)
  - `dist/src/pages/ingestion/index.html`
  - `dist/src/pages/featured/index.html`
  - `dist/assets/` with all JS/CSS bundles

**Step 3: Verify Rust compilation**

```bash
cargo check 2>&1 | grep "error\[" | head -20
```

Expected: Clean.

**Commit:** `feat: admin page routes in Rust, pnpm build verified`
<!-- END_TASK_5 -->

<!-- START_TASK_6 -->
### Task 6: Final Phase 7 verification

**Verifies:** rust-port.AC6.1, and functional verification of AC6.2–AC6.4

**Step 1: Clean pnpm build**

```bash
cd /workspaces/districtlive-server/frontend && pnpm build
```

Expected: Zero TypeScript errors. Three HTML files in `dist/`.

**Step 2: Run full check**

```bash
cd /workspaces/districtlive-server && just check
```

Expected: `cargo fmt --check` and `cargo clippy -- -D warnings` both pass.

**Step 3: Verify Bazel build**

```bash
bazel build //... 2>&1 | tail -10
```

Expected: Successful. The frontend `dist/` files are re-embedded via rust-embed.

**Step 4: Smoke test admin pages (if just dev is running)**

1. Navigate to `http://localhost:8080/src/pages/ingestion/` — should show login form
2. Enter credentials (default: `admin` / `changeme`) — should show source health cards (AC6.2)
3. Click "Trigger" on a source — should call the API and refresh (AC6.3)
4. Navigate to `http://localhost:8080/src/pages/featured/` — should show login + create form (AC6.4)

**Commit:** `chore: phase 7 verification — pnpm build and just check passing`
<!-- END_TASK_6 -->
