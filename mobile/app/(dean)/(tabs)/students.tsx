import { useState } from "react";
import { FlatList, StyleSheet, Text, TextInput, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { PanelShell } from "@/components/panels/PanelShell";
import { DEAN_DRAWER } from "@/components/panels/deanDrawer";
import { AppointmentStatusBadge } from "@/components/panels/AppointmentStatusBadge";
import { fetchDeanStudents } from "@/services/panels/deanPanel";
import { useAuth } from "@/hooks/useAuth";
import { panelColors } from "@/constants/panelTheme";

export default function DeanStudentsScreen() {
  const { user } = useAuth();
  const [search, setSearch] = useState("");
  const { data = [] } = useQuery({ queryKey: ["dean", "students", search], queryFn: () => fetchDeanStudents(search) });
  const male = data.filter((p) => p.gender?.toLowerCase() === "male").length;
  const female = data.length - male;

  return (
    <PanelShell title="Students" drawerHeader={{ name: user?.name ?? "Dean", subtitle: "Students" }} drawerItems={DEAN_DRAWER}>
      <TextInput style={styles.search} placeholder="Search students…" value={search} onChangeText={setSearch} />
      <View style={styles.stats}><Text>All: {data.length}</Text><Text>Male: {male}</Text><Text>Female: {female}</Text></View>
      <FlatList
        data={data}
        keyExtractor={(p) => String(p.id)}
        contentContainerStyle={{ padding: 16, paddingBottom: 80 }}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <View style={styles.av}><Text style={styles.avt}>{item.name.charAt(0)}</Text></View>
            <View style={{ flex: 1 }}><Text style={styles.name}>{item.name}</Text><Text style={styles.sub}>{item.email ?? item.phone}</Text></View>
            <AppointmentStatusBadge status="active" />
          </View>
        )}
      />
    </PanelShell>
  );
}

const styles = StyleSheet.create({
  search: { margin: 16, marginBottom: 0, backgroundColor: panelColors.card, borderRadius: 12, padding: 12, borderWidth: 1, borderColor: panelColors.border },
  stats: { flexDirection: "row", justifyContent: "space-around", padding: 12 },
  card: { flexDirection: "row", gap: 12, backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  av: { width: 44, height: 44, borderRadius: 22, backgroundColor: panelColors.primary, alignItems: "center", justifyContent: "center" },
  avt: { color: "#fff", fontFamily: "Poppins_700Bold" },
  name: { fontFamily: "Poppins_600SemiBold" },
  sub: { fontSize: 12, color: panelColors.textSecondary },
});
