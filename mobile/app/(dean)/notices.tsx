import { FlatList, StyleSheet, Text, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { fetchDeanNotices } from "@/services/panels/deanPanel";
import { panelColors } from "@/constants/panelTheme";

export default function DeanNoticesScreen() {
  const { data = [] } = useQuery({ queryKey: ["dean", "notices"], queryFn: fetchDeanNotices });
  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Notices" />
      <FlatList
        data={data}
        keyExtractor={(n) => n.id}
        contentContainerStyle={{ padding: 16 }}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <Text style={styles.title}>{item.title}</Text>
            <Text style={styles.desc} numberOfLines={2}>{item.description}</Text>
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  card: { backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  title: { fontFamily: "Poppins_700Bold" },
  desc: { fontSize: 13, color: panelColors.textSecondary, marginTop: 6 },
});
