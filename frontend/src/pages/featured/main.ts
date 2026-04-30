import {
  clearCredentials,
  createFeatured,
  getFeaturedHistory,
  storeCredentials,
} from '../../api';
import type { FeaturedEventDto } from '../../types';

const app = document.getElementById('app')!;

// --- Login form ---

function renderLogin(onSuccess: () => void): void {
  app.innerHTML = `
    <h1>Featured Events</h1>
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
    getFeaturedHistory().match(
      (history) => { renderDashboard(history, onSuccess); },
      () => {
        clearCredentials();
        (document.getElementById('login-error') as HTMLElement).textContent = 'Invalid credentials';
      },
    );
  });
}

// --- History row ---

// Admin-only page; server data treated as trusted HTML source.
function historyRow(item: FeaturedEventDto): string {
  const date = new Date(item.created_at).toLocaleString();
  return `
    <tr>
      <td>${date}</td>
      <td>${item.event.title}</td>
      <td>${item.blurb}</td>
      <td>${item.created_by}</td>
    </tr>
  `;
}

// --- Dashboard ---

function renderDashboard(history: Array<FeaturedEventDto>, reload: () => void): void {
  app.innerHTML = `
    <h1>Featured Events</h1>

    <section>
      <h2>Create Featured</h2>
      <form id="create-form">
        <label>Event ID <input type="text" id="event-id" placeholder="uuid" /></label>
        <label>Blurb <textarea id="blurb" rows="3"></textarea></label>
        <button type="submit">Create</button>
        <p id="create-status"></p>
      </form>
    </section>

    <section>
      <h2>History</h2>
      <table>
        <thead><tr><th>Date</th><th>Event</th><th>Blurb</th><th>Created by</th></tr></thead>
        <tbody id="history-body">${history.map(historyRow).join('')}</tbody>
      </table>
    </section>

    <button id="logout">Sign out</button>
  `;

  document.getElementById('create-form')!.addEventListener('submit', (e) => {
    e.preventDefault();
    const eventId = (document.getElementById('event-id') as HTMLInputElement).value.trim();
    const blurb = (document.getElementById('blurb') as HTMLTextAreaElement).value.trim();
    const status = document.getElementById('create-status')!;
    if (!eventId || !blurb) {
      status.textContent = 'Event ID and blurb are required.';
      return;
    }
    status.textContent = 'Creating…';
    createFeatured(eventId, blurb).match(
      () => { status.textContent = 'Created. Reloading…'; setTimeout(reload, 1000); },
      (err) => { status.textContent = `Error: ${err.message}`; },
    );
  });

  document.getElementById('logout')!.addEventListener('click', () => {
    clearCredentials();
    reload();
  });
}

// --- Boot ---

function boot(): void {
  getFeaturedHistory().match(
    (history) => renderDashboard(history, boot),
    (err) => {
      if (err.type === 'unauthorized') {
        renderLogin(boot);
      } else {
        app.innerHTML = `<p>Error loading featured history: ${err.message}</p>`;
      }
    },
  );
}

boot();
