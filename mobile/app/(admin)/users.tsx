import { useState } from "react";
import { FlatList, StyleSheet, Text, TextInput, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { AppointmentStatusBadge } from "@/components/panels/AppointmentStatusBadge";
import { fetchAdminUsers } from "@/services/panels/adminPanel";
import { panelColors } from "@/constants/panelTheme";

export default function AdminUsersScreen() {
  const [search, setSearch] = useState("");
  const { data = [] } = useQuery({ queryKey: ["admin", "users", search], queryFn: () => fetchAdminUsers(search) });
  const active = data.filter((u) => u.active).length;

  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Users" />
      <Text style={styles.stat}>Total: {data.length} · Active: {active}</Text>
      <TextInput style={styles.search} placeholder="Search users…" value={search} onChangeText={setSearch} />
      <FlatList
        data={data}
        keyExtractor={(u) => String(u.id)}
        contentContainerStyle={{ padding: 16 }}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <View style={{ flex: 1 }}>
              <Text style={styles.name}>{item.name}</Text>
              <Text style={styles.sub}>{item.email} · {item.role}</Text>
            </View>
            <AppointmentStatusBadge status={item.active ? "active" : "inactive"} />
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  stat: { textAlign: "center", padding: 8, fontFamily: "Poppins_600SemiBold" },
  search: { marginHorizontal: 16, backgroundColor: panelColors.card, borderRadius: 12, padding: 12, borderWidth: 1, borderColor: panelColors.border },
  card: { flexDirection: "row", backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  name: { fontFamily: "Poppins_600SemiBold" },
  sub: { fontSize: 12, color: panelColors.textSecondary },
});
