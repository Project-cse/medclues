import { useMemo, useState } from "react";
import { FlatList, Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { PanelShell } from "@/components/panels/PanelShell";
import { ADMIN_DRAWER } from "@/components/panels/adminDrawer";
import { AppointmentStatusBadge, appointmentStatusFromRaw } from "@/components/panels/AppointmentStatusBadge";
import { fetchAdminAppointments } from "@/services/panels/adminPanel";
import { useAuth } from "@/hooks/useAuth";
import { panelColors } from "@/constants/panelTheme";

type F = "all" | "confirmed" | "completed" | "cancelled";

export default function AdminAppointmentsScreen() {
  const { user } = useAuth();
  const [filter, setFilter] = useState<F>("all");
  const [search, setSearch] = useState("");
  const { data = [] } = useQuery({
    queryKey: ["admin", "appointments", filter, search],
    queryFn: () => fetchAdminAppointments(filter === "all" ? undefined : filter, search),
  });

  const grouped = useMemo(() => {
    const map = new Map<string, typeof data>();
    data.forEach((a) => {
      const d = a.slotDate ?? "Unknown";
      if (!map.has(d)) map.set(d, []);
      map.get(d)!.push(a);
    });
    return Array.from(map.entries());
  }, [data]);

  return (
    <PanelShell title="Appointments" drawerHeader={{ name: "Admin", subtitle: "Appointments" }} drawerItems={ADMIN_DRAWER}>
      <TextInput style={styles.search} placeholder="Search…" value={search} onChangeText={setSearch} />
      <View style={styles.tabs}>
        {(["all", "confirmed", "completed", "cancelled"] as F[]).map((f) => (
          <Pressable key={f} style={[styles.tab, filter === f && styles.tabOn]} onPress={() => setFilter(f)}>
            <Text style={filter === f ? styles.tabOnT : styles.tabT}>{f}</Text>
          </Pressable>
        ))}
      </View>
      <FlatList
        data={grouped}
        keyExtractor={([d]) => d}
        contentContainerStyle={{ padding: 16, paddingBottom: 80 }}
        renderItem={({ item: [date, list] }) => (
          <View>
            <Text style={styles.date}>{date}</Text>
            {list.map((apt) => (
              <View key={String(apt.id)} style={styles.card}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.name}>{apt.patientName ?? "Patient"}</Text>
                  <Text style={styles.sub}>{apt.slotTime} · {apt.docData?.speciality}</Text>
                </View>
                <AppointmentStatusBadge status={appointmentStatusFromRaw(apt.isCompleted, apt.status)} />
              </View>
            ))}
          </View>
        )}
      />
    </PanelShell>
  );
}

const styles = StyleSheet.create({
  search: { margin: 16, marginBottom: 0, backgroundColor: panelColors.card, borderRadius: 12, padding: 12, borderWidth: 1, borderColor: panelColors.border },
  tabs: { flexDirection: "row", flexWrap: "wrap", padding: 12, gap: 8 },
  tab: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 20, backgroundColor: panelColors.card, borderWidth: 1, borderColor: panelColors.border },
  tabOn: { backgroundColor: panelColors.primary, borderColor: panelColors.primary },
  tabT: { fontSize: 12, color: panelColors.textSecondary, fontFamily: "Poppins_600SemiBold" },
  tabOnT: { fontSize: 12, color: "#fff", fontFamily: "Poppins_600SemiBold" },
  date: { fontFamily: "Poppins_700Bold", marginVertical: 8, color: panelColors.primary },
  card: { flexDirection: "row", backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 8, borderWidth: 1, borderColor: panelColors.border },
  name: { fontFamily: "Poppins_600SemiBold" },
  sub: { fontSize: 12, color: panelColors.textSecondary },
});
