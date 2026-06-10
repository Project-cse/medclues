import type { UserRole } from "@/types/api";

export type DashboardSection =
  | "stats"
  | "appointments"
  | "patients"
  | "schedule"
  | "billing"
  | "notifications";

/** Admin & dean see everything; doctor hides billing; nurse sees patients + appointments only */
export function canSeeSection(
  role: UserRole | null | undefined,
  section: DashboardSection
): boolean {
  if (!role) return false;

  const asAdmin = role === "admin" || role === "dean";

  if (asAdmin) return true;

  if (role === "doctor") {
    return section !== "billing";
  }

  if (role === "nurse") {
    return (
      section === "patients" ||
      section === "appointments" ||
      section === "notifications"
    );
  }

  return section === "appointments" || section === "patients";
}

export function usesDoctorPrefix(role: UserRole | null | undefined): boolean {
  return role === "doctor";
}
