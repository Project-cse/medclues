import { router } from "expo-router";

/** Return to Profile tab — avoids tab stack jumping to Home on back. */
export function navigateBackToProfile(): void {
  router.navigate("/(patient)/profile");
}
