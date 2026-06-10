import { Text, View } from "react-native";
import type { AppointmentStatusKind } from "@/types/dashboard";

const styles: Record<
  AppointmentStatusKind,
  { bg: string; text: string; label: string }
> = {
  confirmed: { bg: "bg-blue-100", text: "text-blue-700", label: "Confirmed" },
  pending: { bg: "bg-amber-100", text: "text-amber-700", label: "Pending" },
  done: { bg: "bg-emerald-100", text: "text-emerald-700", label: "Done" },
};

export function StatusBadge({ status }: { status: AppointmentStatusKind }) {
  const s = styles[status];
  return (
    <View className={`rounded-full px-2.5 py-1 ${s.bg}`}>
      <Text className={`text-xs font-semibold ${s.text}`}>{s.label}</Text>
    </View>
  );
}
