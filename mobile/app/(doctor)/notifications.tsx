import { FlatList, Pressable, Text, StyleSheet, View } from "react-native";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { fetchDoctorNotifications, markNotificationRead } from "@/services/panels/doctorPanel";
import { panelColors } from "@/constants/panelTheme";

export default function DoctorNotificationsScreen() {
  const qc = useQueryClient();
  const { data = [] } = useQuery({ queryKey: ["doctor", "notifications"], queryFn: fetchDoctorNotifications });

  const markAll = async () => {
    await Promise.all(data.map((n) => markNotificationRead(n.id)));
    qc.invalidateQueries({ queryKey: ["doctor", "notifications"] });
  };

  return (
    <View style={styles.safe}>
      <View style={styles.topRow}>
        <ScreenHeader title="Notifications" />
        <Pressable onPress={markAll} style={styles.markBtn}>
          <Text style={styles.mark}>Mark all read</Text>
        </Pressable>
      </View>
      <FlatList
        data={data}
        keyExtractor={(n) => n.id}
        contentContainerStyle={{ padding: 16 }}
        renderItem={({ item }) => (
          <View style={[styles.card, !item.read && styles.unread]}>
            <Text style={styles.title}>{item.title}</Text>
            <Text style={styles.body}>{item.body}</Text>
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: panelColors.background },
  topRow: { position: "relative" },
  markBtn: { position: "absolute", right: 16, top: 14, zIndex: 2 },
  mark: { color: panelColors.primary, fontFamily: "Poppins_600SemiBold", fontSize: 13 },
  card: { backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  unread: { borderLeftWidth: 3, borderLeftColor: panelColors.primary },
  title: { fontFamily: "Poppins_600SemiBold" },
  body: { fontSize: 13, color: panelColors.textSecondary, marginTop: 4 },
});
