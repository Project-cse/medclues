import { StyleSheet, Text, View } from "react-native";
import { panelColors } from "@/constants/panelTheme";

export type AptStatus = "completed" | "upcoming" | "pending" | "cancelled" | "active" | "inactive";

const MAP: Record<AptStatus, { bg: string; color: string; label: string }> = {
  completed: { bg: "#E8F5E9", color: panelColors.completed, label: "Completed" },
  upcoming: { bg: "#E3F2FD", color: panelColors.upcoming, label: "Upcoming" },
  pending: { bg: "#FFF3E0", color: panelColors.pending, label: "Pending" },
  cancelled: { bg: "#FFEBEE", color: panelColors.cancelled, label: "Cancelled" },
  active: { bg: "#E8F5E9", color: panelColors.active, label: "Active" },
  inactive: { bg: "#FFEBEE", color: panelColors.inactive, label: "Inactive" },
};

export function appointmentStatusFromRaw(
  isCompleted?: boolean,
  status?: string,
  cancelled?: boolean
): AptStatus {
  if (cancelled || (status ?? "").toLowerCase().includes("cancel")) return "cancelled";
  if (isCompleted) return "completed";
  if ((status ?? "").toLowerCase() === "pending") return "pending";
  return "upcoming";
}

export function AppointmentStatusBadge({ status, label }: { status: AptStatus; label?: string }) {
  const s = MAP[status];
  return (
    <View style={[styles.badge, { backgroundColor: s.bg }]}>
      <Text style={[styles.text, { color: s.color }]}>{label ?? s.label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: { paddingHorizontal: 10, paddingVertical: 4, borderRadius: 999 },
  text: { fontSize: 11, fontFamily: "Poppins_600SemiBold" },
});
