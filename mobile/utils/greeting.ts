import type { UserRole } from "@/types/api";

export function getTimeGreeting(): string {
  const hour = new Date().getHours();
  if (hour < 12) return "Good Morning";
  if (hour < 17) return "Good Afternoon";
  return "Good Evening";
}

export function formatDashboardGreeting(name: string, role?: UserRole | null): string {
  const period = getTimeGreeting();
  const displayName = name?.trim() || "there";

  if (role === "doctor") {
    return `${period}, Dr. ${displayName}`;
  }
  if (role === "nurse") {
    return `${period}, Nurse ${displayName}`;
  }
  if (role === "admin" || role === "dean") {
    return `${period}, ${displayName}`;
  }
  return `${period}, ${displayName}`;
}
