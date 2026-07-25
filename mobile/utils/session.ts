/** Callback registered by root layout for 401 → login redirect */
let unauthorizedHandler: (() => void) | null = null;

export function setUnauthorizedHandler(handler: () => void) {
  unauthorizedHandler = handler;
}

export function triggerUnauthorized() {
  unauthorizedHandler?.();
}
