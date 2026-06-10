import { RefreshControl, ScrollView, StyleSheet, Text, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { LinearGradient } from "expo-linear-gradient";
import { PanelShell } from "@/components/panels/PanelShell";
import { DEAN_DRAWER } from "@/components/panels/deanDrawer";
import { StatCardPanel } from "@/components/panels/StatCardPanel";
import { fetchDeanDashboard } from "@/services/panels/deanPanel";
import { useAuth } from "@/hooks/useAuth";
import { panelColors } from "@/constants/panelTheme";
import { getTimeGreeting } from "@/utils/greeting";
import { useState, useCallback } from "react";
import { DeanDashboardCharts } from "@/src/screens/DeanDashboardCharts";

export default function DeanDashboardScreen() {
  const { user } = useAuth();
  const [refreshing, setRefreshing] = useState(false);
  const { data, refetch, isLoading } = useQuery({ queryKey: ["dean", "dashboard"], queryFn: fetchDeanDashboard });
  const onRefresh = useCallback(async () => { setRefreshing(true); await refetch(); setRefreshing(false); }, [refetch]);

  return (
    <PanelShell
      drawerHeader={{ name: user?.name ?? "Dean", subtitle: String(data?.hospital?.name ?? "Hospital Dean") }}
      drawerItems={DEAN_DRAWER}
      notificationCount={data?.pendingApprovals ?? 0}
    >
      <ScrollView refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />} contentContainerStyle={{ paddingBottom: 24 }}>
        <LinearGradient colors={[panelColors.primary, "#0D47A1"]} style={styles.header}>
          <Text style={styles.greet}>{getTimeGreeting()}, Dean 👋</Text>
          <Text style={styles.welcome}>Welcome Back!</Text>
        </LinearGradient>
        <View style={styles.statsRow}>
          <StatCardPanel label="Students" value={isLoading ? "—" : data?.stats.patients ?? 0} change="+12%" />
          <StatCardPanel label="Faculty" value={isLoading ? "—" : data?.doctors.length ?? 0} accent={panelColors.accent} change="+5%" />
        </View>
        <View style={styles.statsRow}>
          <StatCardPanel label="Departments" value={8} />
          <StatCardPanel label="Pending Approvals" value={data?.pendingApprovals ?? 0} accent={panelColors.pending} positive={false} />
        </View>
        <DeanDashboardCharts />

        <Text style={styles.section}>Recent Activities</Text>
        {(data?.activities ?? []).map((a) => (
          <View key={a.id} style={styles.act}>
            <Text style={styles.actTitle}>{a.title}</Text>
            <Text style={styles.actSub}>{a.subtitle} · {a.time}</Text>
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
  statsRow: { flexDirection: "row", gap: 10, paddingHorizontal: 16, marginTop: 12 },
  section: { fontFamily: "Poppins_700Bold", fontSize: 16, margin: 16, marginBottom: 8, color: panelColors.textPrimary },
  act: { marginHorizontal: 16, marginBottom: 8, padding: 14, backgroundColor: panelColors.card, borderRadius: 12, borderWidth: 1, borderColor: panelColors.border },
  actTitle: { fontFamily: "Poppins_600SemiBold" },
  actSub: { fontSize: 12, color: panelColors.textSecondary, marginTop: 4 },
});
