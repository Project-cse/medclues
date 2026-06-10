import { useState } from "react";
import { FlatList, Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { router, type Href } from "expo-router";
import { useQuery } from "@tanstack/react-query";
import { PanelShell } from "@/components/panels/PanelShell";
import { DOCTOR_DRAWER } from "@/components/panels/doctorDrawer";
import { fetchDoctorPatients } from "@/services/panels/doctorPanel";
import { useAuth } from "@/hooks/useAuth";
import { panelColors } from "@/constants/panelTheme";

export default function DoctorPatientsScreen() {
  const { user } = useAuth();
  const [search, setSearch] = useState("");
  const { data = [] } = useQuery({
    queryKey: ["doctor", "patients", search],
    queryFn: async () => {
      const all = await fetchDoctorPatients();
      if (!search.trim()) return all;
      const q = search.toLowerCase();
      return all.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          String(p.phone ?? "").includes(q)
      );
    },
  });

  return (
    <PanelShell
      title="Patients"
      drawerHeader={{ name: user?.name ?? "Doctor", subtitle: "Patients" }}
      drawerItems={DOCTOR_DRAWER}
    >
      <TextInput
        style={styles.search}
        placeholder="Search patients…"
        value={search}
        onChangeText={setSearch}
        placeholderTextColor={panelColors.textSecondary}
      />
      <FlatList
        data={data}
        keyExtractor={(p) => String(p.id)}
        contentContainerStyle={{ padding: 16, paddingBottom: 80 }}
        renderItem={({ item }) => (
          <Pressable
            style={styles.card}
            onPress={() =>
              router.push(
                `/(doctor)/patient-profile?patientId=${encodeURIComponent(String(item.id))}` as Href
              )
            }
          >
            <View style={styles.avatar}>
              <Text style={styles.avatarText}>{item.name.charAt(0)}</Text>
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.name}>{item.name}</Text>
              <Text style={styles.sub}>
                {[item.gender, item.age].filter(Boolean).join(" · ") || item.phone || "—"}
              </Text>
            </View>
          </Pressable>
        )}
      />
    </PanelShell>
  );
}

const styles = StyleSheet.create({
  search: {
    margin: 16,
    marginBottom: 0,
    backgroundColor: panelColors.card,
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderWidth: 1,
    borderColor: panelColors.border,
    fontFamily: "Poppins_400Regular",
  },
  card: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    backgroundColor: panelColors.card,
    borderRadius: 12,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: panelColors.border,
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: panelColors.primary,
    alignItems: "center",
    justifyContent: "center",
  },
  avatarText: { color: "#fff", fontFamily: "Poppins_700Bold", fontSize: 18 },
  name: { fontFamily: "Poppins_600SemiBold", color: panelColors.textPrimary },
  sub: { fontSize: 12, color: panelColors.textSecondary, marginTop: 2 },
});
