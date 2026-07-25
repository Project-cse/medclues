import { Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { DashboardSection } from "./DashboardSection";
import { EmptyState } from "./EmptyState";
import { ListSkeleton } from "./Skeleton";
import type { ScheduleSlot } from "@/types/api";

interface DoctorScheduleSectionProps {
  slots: ScheduleSlot[];
  loading?: boolean;
}

export function DoctorScheduleSection({
  slots,
  loading,
}: DoctorScheduleSectionProps) {
  return (
    <DashboardSection title="Today's Schedule">
      {loading ? (
        <ListSkeleton rows={4} />
      ) : slots.length === 0 ? (
        <EmptyState
          icon="time-outline"
          title="No schedule for today"
          message="Time slots will appear when appointments are booked."
        />
      ) : (
        <View className="rounded-xl bg-white p-2 shadow-sm">
          {slots.map((slot, index) => (
            <View
              key={String(slot.id ?? slot.appointmentId ?? index)}
              className={`flex-row items-center gap-3 p-3 ${
                index < slots.length - 1 ? "border-b border-slate-100" : ""
              }`}
            >
              <View className="w-16">
                <Text className="text-sm font-bold text-primary-600">
                  {slot.slotTime ?? "—"}
                </Text>
              </View>
              <View className="h-8 w-px bg-slate-200" />
              <View className="flex-1 flex-row items-center gap-2">
                <Ionicons name="person-circle-outline" size={20} color="#94a3b8" />
                <Text className="flex-1 text-sm font-medium text-slate-800">
                  {slot.patientName ?? "Available"}
                </Text>
              </View>
            </View>
          ))}
        </View>
      )}
    </DashboardSection>
  );
}
