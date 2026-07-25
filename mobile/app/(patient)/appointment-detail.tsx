import type { ReactNode } from "react";
import { StyleSheet, Text, View } from "react-native";
import { useLocalSearchParams } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { useQuery } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { ScreenLoader } from "@/components/animations/ScreenLoader";
import { ErrorState } from "@/components/ui/ErrorState";
import { AvatarImage } from "@/components/ui/AvatarImage";
import { StatusPill } from "@/components/ui/StatusPill";
import { appointmentService } from "@/services/appointments";
import { navigateBackToAppointments } from "@/utils/appointmentNavigation";
import { formatSlotDate } from "@/utils/format";
import { useColors } from "@/hooks/useColors";
import { MedicalMetaIcon } from "@/components/ui/MedicalMetaIcon";

export default function AppointmentDetailScreen() {
  const colors = useColors();
  const { id } = useLocalSearchParams<{ id: string }>();

  const { data: appointment, isLoading, error, refetch } = useQuery({
    queryKey: ["appointment", id],
    queryFn: () => appointmentService.getById(id!),
    enabled: Boolean(id),
  });

  if (isLoading) {
    return <ScreenLoader message="Loading appointment..." />;
  }

  if (error || !appointment) {
    return (
      <SafeAreaView style={[styles.safe, { backgroundColor: colors.background }]} edges={["top"]}>
        <ScreenHeader title="Appointment Details" onBack={navigateBackToAppointments} />
        <ErrorState
          message={error instanceof Error ? error.message : "Appointment not found"}
          onRetry={() => refetch()}
        />
      </SafeAreaView>
    );
  }

  const isUpcoming =
    !appointment.cancelled &&
    !appointment.isCompleted &&
    appointment.status !== "cancelled" &&
    appointment.status !== "completed";

  const statusLabel = appointment.cancelled
    ? "Cancelled"
    : appointment.isCompleted || appointment.status === "completed"
      ? "Completed"
      : "Upcoming";

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: colors.background }]} edges={["top"]}>
      <ScreenHeader title="Appointment Details" onBack={navigateBackToAppointments} />

      <View style={[styles.card, colors.shadows.card, { backgroundColor: colors.white }]}>
        <View style={styles.doctorRow}>
          <AvatarImage uri={appointment.doctor.profilePicUrl} size={72} />
          <View style={styles.doctorInfo}>
            <Text style={[styles.doctorName, { color: colors.textPrimary }]}>
              {appointment.doctor.name}
            </Text>
            {appointment.doctor.specialization ? (
              <Text style={[styles.spec, { color: colors.textSecondary }]}>
                {appointment.doctor.specialization}
              </Text>
            ) : null}
            {isUpcoming ? <StatusPill variant="upcoming" /> : null}
          </View>
        </View>

        <View style={[styles.divider, { backgroundColor: colors.border }]} />

        <DetailRow variant="calendar" label="Date & time">
          {formatSlotDate(appointment.date)} • {appointment.time}
        </DetailRow>

        {appointment.hospital.name ? (
          <DetailRow variant="hospital" label="Hospital">
            {appointment.hospital.name}
          </DetailRow>
        ) : null}

        {appointment.hospital.address ? (
          <DetailRow variant="hospital" label="Location">
            {appointment.hospital.address}
          </DetailRow>
        ) : null}

        <DetailRow variant="status" label="Status">
          {statusLabel}
        </DetailRow>

        {appointment.amount != null ? (
          <DetailRow variant="status" label="Consultation fee">
            ₹{appointment.amount}
          </DetailRow>
        ) : null}

        <DetailRow variant="status" label="Appointment ID">
          {String(appointment.id)}
        </DetailRow>
      </View>
    </SafeAreaView>
  );
}

function DetailRow({
  variant,
  label,
  children,
}: {
  variant: "calendar" | "hospital" | "status";
  label: string;
  children: ReactNode;
}) {
  const colors = useColors();
  return (
    <View style={styles.detailRow}>
      <MedicalMetaIcon variant={variant} size={14} />
      <View style={styles.detailText}>
        <Text style={[styles.detailLabel, { color: colors.textSecondary }]}>{label}</Text>
        <Text style={[styles.detailValue, { color: colors.textPrimary }]}>{children}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  card: {
    margin: 16,
    borderRadius: 16,
    padding: 20,
  },
  doctorRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 16,
  },
  doctorInfo: { flex: 1, gap: 4 },
  doctorName: {
    fontFamily: "Poppins_700Bold",
    fontSize: 18,
  },
  spec: {
    fontFamily: "Poppins_400Regular",
    fontSize: 14,
  },
  divider: {
    height: 1,
    marginVertical: 16,
  },
  detailRow: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 12,
    marginBottom: 14,
  },
  detailText: { flex: 1 },
  detailLabel: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 12,
  },
  detailValue: {
    fontFamily: "Poppins_400Regular",
    fontSize: 15,
    marginTop: 2,
  },
});
