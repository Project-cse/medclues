import { useState } from "react";
import { FlatList, StyleSheet, Text, TextInput, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { PanelShell } from "@/components/panels/PanelShell";
import { DEAN_DRAWER } from "@/components/panels/deanDrawer";
import { AppointmentStatusBadge } from "@/components/panels/AppointmentStatusBadge";
import { fetchDeanFaculty } from "@/services/panels/deanPanel";
import { useAuth } from "@/hooks/useAuth";
import { panelColors } from "@/constants/panelTheme";

export default function DeanFacultyScreen() {
  const { user } = useAuth();
  const [search, setSearch] = useState("");
  const { data = [] } = useQuery({ queryKey: ["dean", "faculty", search], queryFn: () => fetchDeanFaculty(search) });

  return (
    <PanelShell title="Faculty" drawerHeader={{ name: user?.name ?? "Dean", subtitle: "Faculty" }} drawerItems={DEAN_DRAWER}>
      <Text style={styles.stat}>Total Faculty: {data.length}</Text>
      <TextInput style={styles.search} placeholder="Search faculty…" value={search} onChangeText={setSearch} />
      <FlatList
        data={data}
        keyExtractor={(d) => String(d.id)}
        contentContainerStyle={{ padding: 16, paddingBottom: 80 }}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <View style={{ flex: 1 }}>
              <Text style={styles.name}>{item.name}</Text>
              <Text style={styles.sub}>{item.designation} · {item.department}</Text>
            </View>
            <AppointmentStatusBadge status={item.active ? "active" : "inactive"} />
          </View>
        )}
      />
    </PanelShell>
  );
}

const styles = StyleSheet.create({
  stat: { textAlign: "center", padding: 8, fontFamily: "Poppins_600SemiBold" },
  search: { marginHorizontal: 16, backgroundColor: panelColors.card, borderRadius: 12, padding: 12, borderWidth: 1, borderColor: panelColors.border },
  card: { flexDirection: "row", backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  name: { fontFamily: "Poppins_600SemiBold" },
  sub: { fontSize: 12, color: panelColors.textSecondary },
});
