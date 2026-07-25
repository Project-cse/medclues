import { ScrollView, StyleSheet, Text, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { StatCardPanel } from "@/components/panels/StatCardPanel";
import { fetchAdminWeeklyDashboard } from "@/services/panels/adminPanel";
import { AppointmentStatusBadge, appointmentStatusFromRaw } from "@/components/panels/AppointmentStatusBadge";
import { panelColors } from "@/constants/panelTheme";

export default function AdminDashboardDetailScreen() {
  const { data, isLoading } = useQuery({ queryKey: ["admin", "dashboard-weekly"], queryFn: fetchAdminWeeklyDashboard });
  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Dashboard" />
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        <Text style={styles.range}>May 20 – 26, 2025</Text>
        <View style={styles.row}>
          <StatCardPanel label="Patients" value={isLoading ? "—" : data?.stats.patients ?? 0} />
          <StatCardPanel label="Appointments" value={isLoading ? "—" : data?.stats.appointments ?? 0} />
        </View>
        <View style={styles.row}>
          <StatCardPanel label="Doctors" value={isLoading ? "—" : data?.stats.totalDoctors ?? 0} />
          <StatCardPanel label="Revenue" value={isLoading ? "—" : `₹${data?.stats.revenueTotal ?? 0}`} />
        </View>
        <Text style={styles.h}>Recent Appointments</Text>
        {(data?.appointments ?? []).slice(0, 15).map((apt) => (
          <View key={String(apt.id)} style={styles.apt}>
            <View style={{ flex: 1 }}>
              <Text style={styles.name}>{apt.patientName ?? "Patient"}</Text>
              <Text style={styles.sub}>{apt.slotDate} {apt.slotTime}</Text>
            </View>
            <AppointmentStatusBadge status={appointmentStatusFromRaw(apt.isCompleted, apt.status)} />
          </View>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  range: { fontFamily: "Poppins_600SemiBold", color: panelColors.primary, marginBottom: 12 },
  row: { flexDirection: "row", gap: 10, marginBottom: 12 },
  h: { fontFamily: "Poppins_700Bold", marginVertical: 12 },
  apt: { flexDirection: "row", backgroundColor: panelColors.card, padding: 12, borderRadius: 12, marginBottom: 8, borderWidth: 1, borderColor: panelColors.border },
  name: { fontFamily: "Poppins_600SemiBold" },
  sub: { fontSize: 12, color: panelColors.textSecondary },
});
