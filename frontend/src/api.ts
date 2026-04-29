import {ResultAsync} from "neverthrow";

export const api = {
  greet: (name?: string) =>
    ResultAsync.fromPromise(
      fetch(
        name ? `/api/greet?name=${encodeURIComponent(name)}` : "/api/greet",
      ).then((r) => r.text()),
      (e) => ({message: String(e)}),
    ),
};
