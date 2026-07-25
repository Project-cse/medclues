import { FlatList, Pressable, StyleSheet, Text, View } from "react-native";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { fetchAdminNotifications, markNotificationRead } from "@/services/panels/adminPanel";
import { panelColors } from "@/constants/panelTheme";

export default function AdminNotificationsScreen() {
  const qc = useQueryClient();
  const { data = [] } = useQuery({ queryKey: ["admin", "notifications"], queryFn: fetchAdminNotifications });
  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Notifications" />
      <Pressable style={styles.mark} onPress={async () => { await Promise.all(data.map((n) => markNotificationRead(n.id))); qc.invalidateQueries({ queryKey: ["admin", "notifications"] }); }}>
        <Text style={styles.markT}>Mark all as read</Text>
      </Pressable>
      <FlatList data={data} keyExtractor={(n) => n.id} contentContainerStyle={{ padding: 16 }} renderItem={({ item }) => (
        <View style={styles.card}><Text style={styles.title}>{item.title}</Text><Text style={styles.body}>{item.body}</Text></View>
      )} />
    </View>
  );
}

const styles = StyleSheet.create({
  mark: { alignSelf: "flex-end", marginRight: 16, marginTop: -8 },
  markT: { color: panelColors.primary, fontFamily: "Poppins_600SemiBold" },
  card: { backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  title: { fontFamily: "Poppins_600SemiBold" },
  body: { fontSize: 13, color: panelColors.textSecondary, marginTop: 4 },
});
