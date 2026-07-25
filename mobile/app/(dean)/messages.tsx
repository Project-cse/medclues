import { FlatList, StyleSheet, Text, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { fetchDeanMessages } from "@/services/panels/deanPanel";
import { panelColors } from "@/constants/panelTheme";

export default function DeanMessagesScreen() {
  const { data = [] } = useQuery({ queryKey: ["dean", "messages"], queryFn: fetchDeanMessages });
  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Messages" />
      <FlatList
        data={data}
        keyExtractor={(m) => m.id}
        contentContainerStyle={{ padding: 16 }}
        renderItem={({ item }) => (
          <View style={styles.row}>
            <View style={styles.av}><Text style={styles.avt}>{item.name.charAt(0)}</Text></View>
            <View style={{ flex: 1 }}>
              <Text style={styles.name}>{item.name}</Text>
              <Text style={styles.preview} numberOfLines={1}>{item.preview}</Text>
            </View>
            {item.unread ? <View style={styles.badge}><Text style={styles.badgeT}>{item.unread}</Text></View> : null}
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", gap: 12, backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border, alignItems: "center" },
  av: { width: 44, height: 44, borderRadius: 22, backgroundColor: panelColors.primary, alignItems: "center", justifyContent: "center" },
  avt: { color: "#fff", fontFamily: "Poppins_700Bold" },
  name: { fontFamily: "Poppins_600SemiBold" },
  preview: { fontSize: 12, color: panelColors.textSecondary },
  badge: { backgroundColor: panelColors.primary, borderRadius: 12, minWidth: 22, height: 22, alignItems: "center", justifyContent: "center" },
  badgeT: { color: "#fff", fontSize: 11, fontWeight: "700" },
});
