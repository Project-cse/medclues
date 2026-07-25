import { useState } from "react";
import { FlatList, Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { AppointmentStatusBadge } from "@/components/panels/AppointmentStatusBadge";
import { fetchAdminDoctors, toggleDoctorStatus } from "@/services/panels/adminPanel";
import { panelColors } from "@/constants/panelTheme";

export default function AdminDoctorsScreen() {
  const [search, setSearch] = useState("");
  const qc = useQueryClient();
  const { data = [] } = useQuery({ queryKey: ["admin", "doctors", search], queryFn: () => fetchAdminDoctors(search) });

  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Doctors" />
      <TextInput style={styles.search} placeholder="Search doctors…" value={search} onChangeText={setSearch} />
      <FlatList
        data={data}
        keyExtractor={(d) => String(d.id)}
        contentContainerStyle={{ padding: 16 }}
        renderItem={({ item }) => (
          <Pressable
            style={styles.card}
            onPress={async () => {
              await toggleDoctorStatus(item.id as string | number);
              qc.invalidateQueries({ queryKey: ["admin", "doctors"] });
            }}
          >
            <View style={{ flex: 1 }}>
              <Text style={styles.name}>{item.name}</Text>
              <Text style={styles.sub}>{item.speciality} · {item.degree}</Text>
            </View>
            <AppointmentStatusBadge status={item.active ? "active" : "inactive"} />
          </Pressable>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  search: { margin: 16, backgroundColor: panelColors.card, borderRadius: 12, padding: 12, borderWidth: 1, borderColor: panelColors.border },
  card: { flexDirection: "row", backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  name: { fontFamily: "Poppins_600SemiBold" },
  sub: { fontSize: 12, color: panelColors.textSecondary },
});
