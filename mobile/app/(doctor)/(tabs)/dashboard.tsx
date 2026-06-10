import { useCallback, useState } from "react";
import { Pressable, RefreshControl, ScrollView, StyleSheet, Text, View } from "react-native";
import { router, type Href } from "expo-router";
import { useQuery } from "@tanstack/react-query";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import { PanelShell } from "@/components/panels/PanelShell";
import { DOCTOR_DRAWER } from "@/components/panels/doctorDrawer";
import { StatCardPanel } from "@/components/panels/StatCardPanel";
import {
  AppointmentStatusBadge,
  appointmentStatusFromRaw,
} from "@/components/panels/AppointmentStatusBadge";
import { fetchDoctorDashboard } from "@/services/panels/doctorPanel";
import { useAuth } from "@/hooks/useAuth";
import { panelColors } from "@/constants/panelTheme";
import { getTimeGreeting } from "@/utils/greeting";
import { DoctorDashboardCharts } from "@/src/screens/DoctorDashboardCharts";

const QUICK: { label: string; icon: "medical" | "time" | "people" | "bar-chart"; href: Href }[] = [
  { label: "Prescription", icon: "medical", href: "/(doctor)/new-prescription" as Href },
  { label: "Schedule", icon: "time", href: "/(doctor)/schedule" as Href },
  { label: "Patients", icon: "people", href: "/(doctor)/(tabs)/patients" as Href },
  { label: "Reports", icon: "bar-chart", href: "/(doctor)/(tabs)/reports" as Href },
];

export default function DoctorDashboardScreen() {
  const { user } = useAuth();
  const [refreshing, setRefreshing] = useState(false);
  const { data, refetch, isLoading } = useQuery({
    queryKey: ["doctor", "dashboard"],
    queryFn: fetchDoctorDashboard,
  });

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await refetch();
    setRefreshing(false);
  }, [refetch]);

  const name = String(data?.profile?.name ?? user?.name ?? "Doctor");

  return (
    <PanelShell
      drawerHeader={{ name: `Dr. ${name}`, subtitle: String(data?.profile?.speciality ?? "Physician") }}
      drawerItems={DOCTOR_DRAWER}
      notificationCount={data?.pending ?? 0}
      onNotifications={() => router.push("/(doctor)/notifications" as Href)}
    >
      <ScrollView
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        contentContainerStyle={styles.scroll}
      >
        <LinearGradient colors={[panelColors.primary, "#0D47A1"]} style={styles.header}>
          <Text style={styles.greet}>{getTimeGreeting()}, Dr. {name.split(" ")[0]} 👋</Text>
          <Text style={styles.welcome}>Welcome Back!</Text>
        </LinearGradient>

        {data?.nextAppointment ? (
          <View style={styles.nextCard}>
            <Text style={styles.nextLabel}>Upcoming Appointment</Text>
            <Text style={styles.nextPatient}>{data.nextAppointment.patientName ?? "Patient"}</Text>
            <Text style={styles.nextMeta}>
              {data.nextAppointment.slotTime} · {data.nextAppointment.status ?? "Upcoming"}
            </Text>
            <View style={styles.minsBadge}>
              <Text style={styles.minsText}>Upcoming</Text>
            </View>
          </View>
        ) : null}

        <View style={styles.statsRow}>
          <StatCardPanel label="Today's Appts" value={isLoading ? "—" : data?.today.length ?? 0} />
          <StatCardPanel label="Patients" value={isLoading ? "—" : data?.patientCount ?? 0} accent={panelColors.accent} />
        </View>
        <View style={styles.statsRow}>
          <StatCardPanel label="Completed" value={isLoading ? "—" : data?.completed ?? 0} accent={panelColors.completed} />
          <StatCardPanel label="Pending" value={isLoading ? "—" : data?.pending ?? 0} accent={panelColors.pending} />
        </View>

        <DoctorDashboardCharts />

        <Text style={styles.section}>Quick Actions</Text>
        <View style={styles.quickGrid}>
          {QUICK.map((q) => (
            <Pressable key={q.label} style={styles.quickItem} onPress={() => router.push(q.href)}>
              <Ionicons name={q.icon} size={24} color={panelColors.primary} />
              <Text style={styles.quickLabel}>{q.label}</Text>
            </Pressable>
          ))}
        </View>

        <View style={styles.sectionRow}>
          <Text style={styles.section}>Today&apos;s Schedule</Text>
          <Pressable onPress={() => router.push("/(doctor)/schedule" as Href)}>
            <Text style={styles.link}>View All</Text>
          </Pressable>
        </View>
        {(data?.today ?? []).slice(0, 6).map((apt) => (
          <View key={String(apt.id)} style={styles.aptRow}>
            <Text style={styles.aptTime}>{apt.slotTime ?? "—"}</Text>
            <View style={{ flex: 1 }}>
              <Text style={styles.aptName}>{apt.patientName ?? "Patient"}</Text>
              <Text style={styles.aptSub}>{apt.status ?? "Appointment"}</Text>
            </View>
            <AppointmentStatusBadge
              status={appointmentStatusFromRaw(apt.isCompleted, apt.status)}
            />
          </View>
        ))}
      </ScrollView>
    </PanelShell>
  );
}

const styles = StyleSheet.create({
  scroll: { paddingBottom: 24 },
  header: { margin: 16, borderRadius: 16, padding: 20 },
  greet: { fontFamily: "Poppins_700Bold", fontSize: 18, color: "#fff" },
  welcome: { fontFamily: "Poppins_400Regular", color: "rgba(255,255,255,0.9)", marginTop: 4 },
  nextCard: {
    marginHorizontal: 16,
    marginTop: -8,
    backgroundColor: panelColors.card,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: panelColors.border,
  },
  nextLabel: { fontSize: 12, color: panelColors.textSecondary, fontFamily: "Poppins_600SemiBold" },
  nextPatient: { fontSize: 17, fontFamily: "Poppins_700Bold", color: panelColors.textPrimary, marginTop: 4 },
  nextMeta: { fontSize: 13, color: panelColors.textSecondary, marginTop: 2 },
  minsBadge: {
    alignSelf: "flex-start",
    marginTop: 8,
    backgroundColor: "#FFF3E0",
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 8,
  },
  minsText: { color: panelColors.pending, fontFamily: "Poppins_600SemiBold", fontSize: 11 },
  statsRow: { flexDirection: "row", gap: 10, paddingHorizontal: 16, marginTop: 12 },
  section: {
    fontFamily: "Poppins_700Bold",
    fontSize: 16,
    color: panelColors.textPrimary,
    marginHorizontal: 16,
    marginTop: 20,
    marginBottom: 10,
  },
  sectionRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginHorizontal: 16,
    marginTop: 20,
  },
  link: { color: panelColors.primary, fontFamily: "Poppins_600SemiBold", fontSize: 13 },
  quickGrid: { flexDirection: "row", flexWrap: "wrap", paddingHorizontal: 12, gap: 8 },
  quickItem: {
    width: "47%",
    backgroundColor: panelColors.card,
    borderRadius: 12,
    padding: 16,
    alignItems: "center",
    borderWidth: 1,
    borderColor: panelColors.border,
  },
  quickLabel: { marginTop: 8, fontFamily: "Poppins_600SemiBold", fontSize: 13, color: panelColors.textPrimary },
  aptRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    marginHorizontal: 16,
    marginBottom: 10,
    padding: 12,
    backgroundColor: panelColors.card,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: panelColors.border,
  },
  aptTime: { fontFamily: "Poppins_600SemiBold", color: panelColors.primary, width: 52 },
  aptName: { fontFamily: "Poppins_600SemiBold", color: panelColors.textPrimary },
  aptSub: { fontSize: 12, color: panelColors.textSecondary },
});
