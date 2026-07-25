import type { Href } from "expo-router";
import type { UserRole } from "@/types/api";

/** Where to send the user after successful login */
export function getPostLoginRoute(role: UserRole): Href {
  switch (role) {
    case "patient":
      return "/(patient)/home";
    case "doctor":
      return "/(doctor)/(tabs)/dashboard" as Href;
    case "dean":
      return "/(dean)/(tabs)/dashboard" as Href;
    case "admin":
      return "/(admin)/(tabs)/dashboard" as Href;
    default:
      return "/(tabs)/dashboard";
  }
}

export function isStaffRole(role: UserRole | null | undefined): boolean {
  return role === "doctor" || role === "admin" || role === "dean" || role === "nurse";
}

export function isPatientRole(role: UserRole | null | undefined): boolean {
  return role === "patient";
}

export function getPanelGroup(role: UserRole | null | undefined): "doctor" | "dean" | "admin" | "tabs" | "patient" | null {
  if (role === "doctor") return "doctor";
  if (role === "dean") return "dean";
  if (role === "admin") return "admin";
  if (role === "patient") return "patient";
  if (role === "nurse") return "tabs";
  return null;
}
