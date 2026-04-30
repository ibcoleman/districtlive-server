import {
  clearCredentials,
  getAdminSources,
  storeCredentials,
  triggerIngestion,
  triggerSourceIngestion,
} from '../../api';
import type { SourceHealthDto } from '../../types';

const app = document.getElementById('app')!;

// --- Login form ---

function renderLogin(onSuccess: () => void): void {
  app.innerHTML = `
    <h1>Ingestion Monitor</h1>
    <form id="login-form">
      <label>Username <input type="text" id="username" autocomplete="username" /></label>
      <label>Password <input type="password" id="password" autocomplete="current-password" /></label>
      <button type="submit">Sign in</button>
      <p id="login-error" style="color:red"></p>
    </form>
  `;
  document.getElementById('login-form')!.addEventListener('submit', (e) => {
    e.preventDefault();
    const username = (document.getElementById('username') as HTMLInputElement).value;
    const password = (document.getElementById('password') as HTMLInputElement).value;
    storeCredentials(username, password);
    getAdminSources().match(
      (sources) => { renderDashboard(sources, onSuccess); },
      () => {
        clearCredentials();
        (document.getElementById('login-error') as HTMLElement).textContent = 'Invalid credentials';
      },
    );
  });
}

// --- Source health card ---

function sourceCard(source: SourceHealthDto): string {
  const status = source.healthy ? '✓ healthy' : `✗ ${source.consecutive_failures} failures`;
  const lastSuccess = source.last_success_at
    ? new Date(source.last_success_at).toLocaleString()
    : 'never';
  return `
    <div class="source-card" data-id="${source.id}">
      <h3>${source.name}</h3>
      <p>Status: <strong>${status}</strong></p>
      <p>Last success: ${lastSuccess}</p>
      <button class="trigger-btn" data-source-id="${source.id}">Trigger</button>
      <span class="trigger-status"></span>
    </div>
  `;
}

// --- Dashboard ---

function renderDashboard(sources: Array<SourceHealthDto>, reload: () => void): void {
  app.innerHTML = `
    <h1>Ingestion Monitor</h1>
    <button id="trigger-all">Trigger All</button>
    <span id="trigger-all-status"></span>
    <div id="sources">${sources.map(sourceCard).join('')}</div>
    <button id="logout">Sign out</button>
  `;

  document.getElementById('trigger-all')!.addEventListener('click', () => {
    const status = document.getElementById('trigger-all-status')!;
    status.textContent = 'Triggering…';
    triggerIngestion().match(
      () => { status.textContent = 'Triggered. Reloading…'; setTimeout(reload, 1500); },
      (e) => { status.textContent = `Error: ${e.message}`; },
    );
  });

  document.querySelectorAll<HTMLButtonElement>('.trigger-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      const sourceId = btn.dataset['sourceId']!;
      const statusEl = btn.nextElementSibling as HTMLElement;
      statusEl.textContent = 'Triggering…';
      triggerSourceIngestion(sourceId).match(
        () => { statusEl.textContent = 'Done'; },
        (e) => { statusEl.textContent = `Error: ${e.message}`; },
      );
    });
  });

  document.getElementById('logout')!.addEventListener('click', () => {
    clearCredentials();
    reload();
  });
}

// --- Boot ---

function boot(): void {
  getAdminSources().match(
    (sources) => renderDashboard(sources, boot),
    (err) => {
      if (err.type === 'unauthorized') {
        renderLogin(boot);
      } else {
        app.innerHTML = `<p>Error loading sources: ${err.message}</p>`;
      }
    },
  );
}

boot();
