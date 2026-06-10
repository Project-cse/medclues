import { useCallback, useState } from "react";
import { Pressable, RefreshControl, ScrollView, StyleSheet, Text, View } from "react-native";
import { router, type Href } from "expo-router";
import { useQuery } from "@tanstack/react-query";
import { LinearGradient } from "expo-linear-gradient";
import { PanelShell } from "@/components/panels/PanelShell";
import { ADMIN_DRAWER } from "@/components/panels/adminDrawer";
import { StatCardPanel } from "@/components/panels/StatCardPanel";
import { AppointmentStatusBadge, appointmentStatusFromRaw } from "@/components/panels/AppointmentStatusBadge";
import { fetchAdminDashboard } from "@/services/panels/adminPanel";
import { useAuth } from "@/hooks/useAuth";
import { panelColors } from "@/constants/panelTheme";
import { getTimeGreeting } from "@/utils/greeting";
import { AdminDashboardCharts } from "@/src/screens/AdminDashboardCharts";

export default function AdminDashboardScreen() {
  const { user } = useAuth();
  const [refreshing, setRefreshing] = useState(false);
  const { data, refetch, isLoading } = useQuery({ queryKey: ["admin", "dashboard"], queryFn: fetchAdminDashboard });
  const onRefresh = useCallback(async () => { setRefreshing(true); await refetch(); setRefreshing(false); }, [refetch]);

  return (
    <PanelShell
      drawerHeader={{ name: "MediChain+", subtitle: user?.email ?? "Super Admin" }}
      drawerItems={ADMIN_DRAWER}
      onNotifications={() => router.push("/(admin)/notifications" as Href)}
    >
      <ScrollView refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />} contentContainerStyle={{ paddingBottom: 24 }}>
        <LinearGradient colors={[panelColors.primary, "#0D47A1"]} style={styles.header}>
          <Text style={styles.greet}>{getTimeGreeting()}, Admin! 👋</Text>
          <Text style={styles.welcome}>Welcome Back</Text>
        </LinearGradient>
        <Pressable onPress={() => router.push("/(admin)/dashboard-detail" as Href)}>
          <Text style={styles.detailLink}>View weekly detail →</Text>
        </Pressable>
        <View style={styles.statsRow}>
          <StatCardPanel label="Patients" value={isLoading ? "—" : data?.stats.patients ?? 0} change="+8%" />
          <StatCardPanel label="Appointments" value={isLoading ? "—" : data?.stats.appointments ?? 0} accent={panelColors.accent} />
        </View>
        <View style={styles.statsRow}>
          <StatCardPanel label="Doctors" value={isLoading ? "—" : data?.stats.totalDoctors ?? 0} />
          <StatCardPanel label="Revenue" value={isLoading ? "—" : `₹${data?.stats.revenueTotal ?? 0}`} accent={panelColors.completed} />
        </View>
        <AdminDashboardCharts />

        <View style={styles.sectionRow}>
          <Text style={styles.section}>Recent Appointments</Text>
          <Pressable onPress={() => router.push("/(admin)/(tabs)/appointments" as Href)}>
            <Text style={styles.link}>View All</Text>
          </Pressable>
        </View>
        {(data?.appointments ?? []).map((apt) => (
          <View key={String(apt.id)} style={styles.apt}>
            <View style={{ flex: 1 }}>
              <Text style={styles.aptName}>{apt.patientName ?? "Patient"}</Text>
              <Text style={styles.aptSub}>{apt.slotTime} · {apt.docData?.speciality ?? "Doctor"}</Text>
            </View>
            <AppointmentStatusBadge status={appointmentStatusFromRaw(apt.isCompleted, apt.status)} />
          </View>
        ))}
      </ScrollView>
    </PanelShell>
  );
}

const styles = StyleSheet.create({
  header: { margin: 16, borderRadius: 16, padding: 20 },
  greet: { fontFamily: "Poppins_700Bold", fontSize: 18, color: "#fff" },
  welcome: { color: "rgba(255,255,255,0.9)", marginTop: 4 },
  detailLink: { textAlign: "right", marginRight: 16, color: panelColors.primary, fontFamily: "Poppins_600SemiBold" },
  statsRow: { flexDirection: "row", gap: 10, paddingHorizontal: 16, marginTop: 12 },
  sectionRow: { flexDirection: "row", justifyContent: "space-between", marginHorizontal: 16, marginTop: 20 },
  section: { fontFamily: "Poppins_700Bold", fontSize: 16 },
  link: { color: panelColors.primary, fontFamily: "Poppins_600SemiBold" },
  apt: { flexDirection: "row", marginHorizontal: 16, marginBottom: 10, padding: 12, backgroundColor: panelColors.card, borderRadius: 12, borderWidth: 1, borderColor: panelColors.border },
  aptName: { fontFamily: "Poppins_600SemiBold" },
  aptSub: { fontSize: 12, color: panelColors.textSecondary },
});
