type ToastFn = (message: string, type?: "success" | "error" | "info") => void;

let showGlobalToast: ToastFn | null = null;

export function registerApiToast(fn: ToastFn) {
  showGlobalToast = fn;
}

export function apiToast(message: string, type: "success" | "error" | "info" = "error") {
  showGlobalToast?.(message, type);
}
