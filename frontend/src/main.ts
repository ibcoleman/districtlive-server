import {api} from "./api";

// DOM references
const appDiv = document.getElementById("app");
const greetingDiv = document.createElement("div");
greetingDiv.id = "greeting";


// Mount elements
if (appDiv) {
  appDiv.appendChild(greetingDiv);
}

// Load greeting on page load
async function loadGreeting(): Promise<void> {
  const result = await api.greet();

  result.match(
    (greeting) => {
      greetingDiv.textContent = greeting;
    },
    (error) => {
      greetingDiv.textContent = `Error: ${error.message}`;
    },
  );
}


// Initialize on load
loadGreeting().catch((e) => console.error("Failed to load greeting:", e));
