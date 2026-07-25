import { router } from "expo-router";

/** Return to My Appointments tab after viewing appointment details. */
export function navigateBackToAppointments(): void {
  router.navigate("/(patient)/appointments");
}
