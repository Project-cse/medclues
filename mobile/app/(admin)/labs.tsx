import { useState } from "react";
import { FlatList, Pressable, StyleSheet, Text, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { fetchAdminLabs, fetchAdminBloodBanks } from "@/services/panels/adminPanel";
import { panelColors } from "@/constants/panelTheme";

export default function AdminLabsScreen() {
  const [tab, setTab] = useState<"labs" | "blood">("labs");
  const labs = useQuery({ queryKey: ["admin", "labs"], queryFn: fetchAdminLabs });
  const banks = useQuery({ queryKey: ["admin", "blood"], queryFn: fetchAdminBloodBanks });
  const data = tab === "labs" ? (labs.data ?? []) : (banks.data ?? []);

  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Labs" />
      <View style={styles.tabs}>
        <Pressable style={[styles.tab, tab === "labs" && styles.tabOn]} onPress={() => setTab("labs")}><Text style={tab === "labs" ? styles.tabOnT : styles.tabT}>All Labs</Text></Pressable>
        <Pressable style={[styles.tab, tab === "blood" && styles.tabOn]} onPress={() => setTab("blood")}><Text style={tab === "blood" ? styles.tabOnT : styles.tabT}>Blood Banks</Text></Pressable>
      </View>
      <FlatList
        data={data}
        keyExtractor={(item, i) => String((item as Record<string, unknown>).id ?? i)}
        contentContainerStyle={{ padding: 16 }}
        renderItem={({ item }) => {
          const r = item as Record<string, unknown>;
          return (
            <View style={styles.card}>
              <Text style={styles.name}>{String(r.name ?? r.labName ?? "Lab")}</Text>
              <Text style={styles.sub}>{String(r.address ?? r.location ?? "")}</Text>
            </View>
          );
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  tabs: { flexDirection: "row", padding: 12, gap: 8 },
  tab: { flex: 1, padding: 10, borderRadius: 10, backgroundColor: panelColors.card, alignItems: "center" },
  tabOn: { backgroundColor: panelColors.primary },
  tabT: { fontFamily: "Poppins_600SemiBold", color: panelColors.textSecondary },
  tabOnT: { color: "#fff", fontFamily: "Poppins_600SemiBold" },
  card: { backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  name: { fontFamily: "Poppins_600SemiBold" },
  sub: { fontSize: 12, color: panelColors.textSecondary },
});
