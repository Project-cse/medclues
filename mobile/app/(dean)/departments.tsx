import { FlatList, StyleSheet, Text, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { fetchDeanDepartments } from "@/services/panels/deanPanel";
import { panelColors } from "@/constants/panelTheme";

export default function DeanDepartmentsScreen() {
  const { data = [] } = useQuery({ queryKey: ["dean", "departments"], queryFn: fetchDeanDepartments });
  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Departments" />
      <FlatList
        data={data}
        keyExtractor={(d) => String(d.id)}
        contentContainerStyle={{ padding: 16 }}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <View style={[styles.dot, { backgroundColor: item.color }]} />
            <View style={{ flex: 1 }}>
              <Text style={styles.name}>{item.name}</Text>
              <Text style={styles.sub}>Faculty: {item.facultyCount} · Students: {item.studentCount}</Text>
            </View>
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  card: { flexDirection: "row", gap: 12, backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  dot: { width: 12, height: 12, borderRadius: 6, marginTop: 6 },
  name: { fontFamily: "Poppins_600SemiBold" },
  sub: { fontSize: 12, color: panelColors.textSecondary },
});
