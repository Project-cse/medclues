import { Text, View } from "react-native";
import { DashboardSection } from "./DashboardSection";
import { EmptyState } from "./EmptyState";
import { ListSkeleton } from "./Skeleton";
import { StatusBadge } from "./StatusBadge";
import type { DashboardAppointment } from "@/types/dashboard";

interface TodayAppointmentsSectionProps {
  appointments: DashboardAppointment[];
  loading?: boolean;
  onViewAll: () => void;
}

export function TodayAppointmentsSection({
  appointments,
  loading,
  onViewAll,
}: TodayAppointmentsSectionProps) {
  return (
    <DashboardSection title="Today's Appointments" onViewAll={onViewAll}>
      {loading ? (
        <ListSkeleton rows={3} />
      ) : appointments.length === 0 ? (
        <EmptyState
          icon="calendar-outline"
          title="No appointments today"
          message="New bookings will appear here."
        />
      ) : (
        <View className="gap-2">
          {appointments.map((apt) => (
            <View
              key={String(apt.id)}
              className="flex-row items-center justify-between rounded-xl bg-white p-4 shadow-sm"
            >
              <View className="flex-1 pr-2">
                <Text className="font-semibold text-slate-900">
                  {apt.patientName ?? apt.userData?.name ?? "Patient"}
                </Text>
                <Text className="mt-0.5 text-sm text-slate-500">
                  {apt.slotTime ?? "—"} · Dr.{" "}
                  {apt.doctorName ?? apt.docData?.name ?? "—"}
                </Text>
              </View>
              <StatusBadge status={apt.statusKind} />
            </View>
          ))}
        </View>
      )}
    </DashboardSection>
  );
}
