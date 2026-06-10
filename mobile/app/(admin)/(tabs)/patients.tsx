import { useState } from "react";
import { FlatList, StyleSheet, Text, TextInput, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { PanelShell } from "@/components/panels/PanelShell";
import { ADMIN_DRAWER } from "@/components/panels/adminDrawer";
import { fetchAdminPatients } from "@/services/panels/adminPanel";
import { useAuth } from "@/hooks/useAuth";
import { panelColors } from "@/constants/panelTheme";

export default function AdminPatientsScreen() {
  const { user } = useAuth();
  const [search, setSearch] = useState("");
  const { data = [] } = useQuery({ queryKey: ["admin", "patients", search], queryFn: () => fetchAdminPatients(search) });

  return (
    <PanelShell title="Patients" drawerHeader={{ name: "Admin", subtitle: "Patients" }} drawerItems={ADMIN_DRAWER}>
      <TextInput style={styles.search} placeholder="Search patients…" value={search} onChangeText={setSearch} />
      <FlatList
        data={data}
        keyExtractor={(p) => String(p.id)}
        contentContainerStyle={{ padding: 16, paddingBottom: 80 }}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <Text style={styles.name}>{item.name}</Text>
            <Text style={styles.sub}>{[item.gender, item.phone].filter(Boolean).join(" · ")}</Text>
          </View>
        )}
      />
    </PanelShell>
  );
}

const styles = StyleSheet.create({
  search: { margin: 16, marginBottom: 0, backgroundColor: panelColors.card, borderRadius: 12, padding: 12, borderWidth: 1, borderColor: panelColors.border },
  card: { backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  name: { fontFamily: "Poppins_600SemiBold" },
  sub: { fontSize: 12, color: panelColors.textSecondary },
});
