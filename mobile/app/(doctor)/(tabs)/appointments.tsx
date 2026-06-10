import { useMemo, useState } from "react";
import { FlatList, Pressable, StyleSheet, Text, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { PanelShell } from "@/components/panels/PanelShell";
import { DOCTOR_DRAWER } from "@/components/panels/doctorDrawer";
import {
  AppointmentStatusBadge,
  appointmentStatusFromRaw,
} from "@/components/panels/AppointmentStatusBadge";
import { fetchDoctorAppointments } from "@/services/panels/doctorPanel";
import { useAuth } from "@/hooks/useAuth";
import { panelColors } from "@/constants/panelTheme";

type Filter = "all" | "upcoming" | "completed" | "cancelled";

export default function DoctorAppointmentsScreen() {
  const { user } = useAuth();
  const [filter, setFilter] = useState<Filter>("all");
  const { data = [], isLoading } = useQuery({
    queryKey: ["doctor", "appointments"],
    queryFn: () => fetchDoctorAppointments(),
  });

  const filtered = useMemo(() => {
    return data.filter((a) => {
      const st = appointmentStatusFromRaw(a.isCompleted, a.status);
      if (filter === "all") return true;
      if (filter === "completed") return st === "completed";
      if (filter === "cancelled") return st === "cancelled";
      return st === "upcoming" || st === "pending";
    });
  }, [data, filter]);

  const counts = useMemo(
    () => ({
      all: data.length,
      upcoming: data.filter((a) => !a.isCompleted && !String(a.status).includes("cancel")).length,
      completed: data.filter((a) => a.isCompleted).length,
      cancelled: data.filter((a) => String(a.status).includes("cancel")).length,
    }),
    [data]
  );

  return (
    <PanelShell
      title="Appointments"
      drawerHeader={{ name: user?.name ?? "Doctor", subtitle: "Appointments" }}
      drawerItems={DOCTOR_DRAWER}
    >
      <View style={styles.tabs}>
        {(["all", "upcoming", "completed", "cancelled"] as Filter[]).map((f) => (
          <Pressable key={f} style={[styles.tab, filter === f && styles.tabActive]} onPress={() => setFilter(f)}>
            <Text style={[styles.tabText, filter === f && styles.tabTextActive]}>
              {f[0].toUpperCase() + f.slice(1)} {counts[f]}
            </Text>
          </Pressable>
        ))}
      </View>
      <FlatList
        data={filtered}
        keyExtractor={(item) => String(item.id)}
        contentContainerStyle={{ padding: 16, paddingBottom: 80 }}
        ListEmptyComponent={
          <Text style={styles.empty}>{isLoading ? "Loading…" : "No appointments"}</Text>
        }
        renderItem={({ item }) => (
          <View style={styles.card}>
            <Text style={styles.time}>{item.slotTime ?? "—"}</Text>
            <View style={{ flex: 1 }}>
              <Text style={styles.name}>{item.patientName ?? "Patient"}</Text>
              <Text style={styles.sub}>{item.slotDate}</Text>
            </View>
            <AppointmentStatusBadge status={appointmentStatusFromRaw(item.isCompleted, item.status)} />
          </View>
        )}
      />
    </PanelShell>
  );
}

const styles = StyleSheet.create({
  tabs: { flexDirection: "row", flexWrap: "wrap", padding: 12, gap: 8 },
  tab: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 20, backgroundColor: panelColors.card, borderWidth: 1, borderColor: panelColors.border },
  tabActive: { backgroundColor: panelColors.primary, borderColor: panelColors.primary },
  tabText: { fontSize: 12, fontFamily: "Poppins_600SemiBold", color: panelColors.textSecondary },
  tabTextActive: { color: "#fff" },
  card: { flexDirection: "row", alignItems: "center", gap: 12, backgroundColor: panelColors.card, borderRadius: 12, padding: 14, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  time: { fontFamily: "Poppins_700Bold", color: panelColors.primary, width: 56 },
  name: { fontFamily: "Poppins_600SemiBold", color: panelColors.textPrimary },
  sub: { fontSize: 12, color: panelColors.textSecondary },
  empty: { textAlign: "center", color: panelColors.textSecondary, marginTop: 40 },
});
