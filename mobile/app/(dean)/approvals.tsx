import { useState } from "react";
import { FlatList, Pressable, StyleSheet, Text, View } from "react-native";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { approveDeanItem, fetchDeanApprovals, rejectDeanItem } from "@/services/panels/deanPanel";
import { panelColors } from "@/constants/panelTheme";

export default function DeanApprovalsScreen() {
  const [tab, setTab] = useState<"pending" | "completed">("pending");
  const qc = useQueryClient();
  const { data = [] } = useQuery({
    queryKey: ["dean", "approvals", tab],
    queryFn: () => fetchDeanApprovals(tab),
  });
  type ApprovalItem = Awaited<ReturnType<typeof fetchDeanApprovals>>[number];

  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Approvals" />
      <View style={styles.tabs}>
        {(["pending", "completed"] as const).map((t) => (
          <Pressable key={t} style={[styles.tab, tab === t && styles.tabOn]} onPress={() => setTab(t)}>
            <Text style={tab === t ? styles.tabOnText : styles.tabText}>{t}</Text>
          </Pressable>
        ))}
      </View>
      <FlatList<ApprovalItem>
        data={data}
        keyExtractor={(a) => a.id}
        contentContainerStyle={{ padding: 16 }}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <Text style={styles.type}>{item.type}</Text>
            <Text style={styles.name}>{item.requesterName}</Text>
            <Text style={styles.desc}>{item.description}</Text>
            {tab === "pending" ? (
              <View style={styles.actions}>
                <Pressable style={styles.reject} onPress={() => { rejectDeanItem(item.id); qc.invalidateQueries({ queryKey: ["dean", "approvals"] }); }}>
                  <Text style={styles.rejectT}>Reject</Text>
                </Pressable>
                <Pressable style={styles.approve} onPress={() => { approveDeanItem(item.id); qc.invalidateQueries({ queryKey: ["dean", "approvals"] }); }}>
                  <Text style={styles.approveT}>Approve</Text>
                </Pressable>
              </View>
            ) : null}
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  tabs: { flexDirection: "row", padding: 12, gap: 8 },
  tab: { flex: 1, padding: 10, borderRadius: 10, backgroundColor: panelColors.card, alignItems: "center" },
  tabOn: { backgroundColor: panelColors.primary },
  tabText: { fontFamily: "Poppins_600SemiBold", color: panelColors.textSecondary },
  tabOnText: { color: "#fff", fontFamily: "Poppins_600SemiBold" },
  card: { backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  type: { fontFamily: "Poppins_700Bold", color: panelColors.primary },
  name: { fontFamily: "Poppins_600SemiBold", marginTop: 4 },
  desc: { fontSize: 12, color: panelColors.textSecondary, marginVertical: 8 },
  actions: { flexDirection: "row", gap: 10 },
  reject: { flex: 1, borderWidth: 1, borderColor: panelColors.cancelled, padding: 10, borderRadius: 10, alignItems: "center" },
  rejectT: { color: panelColors.cancelled, fontFamily: "Poppins_600SemiBold" },
  approve: { flex: 1, backgroundColor: panelColors.completed, padding: 10, borderRadius: 10, alignItems: "center" },
  approveT: { color: "#fff", fontFamily: "Poppins_600SemiBold" },
});
