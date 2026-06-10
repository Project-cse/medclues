import { Pressable, RefreshControl, ScrollView, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { useRecordCounts } from "@/hooks/useRecords";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { ErrorState } from "@/components/ui/ErrorState";
import { useToast } from "@/providers/ToastProvider";
import { useColors } from "@/hooks/useColors";

const ROWS = [
  { key: "prescriptions" as const, title: "Prescriptions", icon: "document-text", color: "#10B981", bg: "#D1FAE5" },
  { key: "labReports" as const, title: "Lab Reports", icon: "flask", color: "#EF4444", bg: "#FEE2E2" },
  { key: "medicalHistory" as const, title: "Medical History", icon: "book", color: "#2563EB", bg: "#DBEAFE" },
  { key: "vaccinations" as const, title: "Vaccination", icon: "medical", color: "#0EA5E9", bg: "#E0F2FE" },
  { key: "allergies" as const, title: "Allergies", icon: "leaf", color: "#F97316", bg: "#FFEDD5" },
  { key: "vitals" as const, title: "Vitals", icon: "heart", color: "#EF4444", bg: "#FEE2E2" },
];

export default function HealthRecordsScreen() {
  const colors = useColors();
  const { showToast } = useToast();
  const { data: counts, isLoading, error, refetch, isRefetching } = useRecordCounts();

  if (isLoading) {
    return (
      <SafeAreaView style={[styles.safe, { backgroundColor: colors.background }]} edges={["top"]}>
        <ScreenHeader title="My Health Records" showBack={false} centerTitle />
        <ListSkeleton rows={4} />
      </SafeAreaView>
    );
  }

  if (error) {
    return (
      <SafeAreaView style={[styles.safe, { backgroundColor: colors.background }]} edges={["top"]}>
        <ScreenHeader title="My Health Records" showBack={false} centerTitle />
        <ErrorState
          message={error instanceof Error ? error.message : "Failed to load records"}
          onRetry={() => refetch()}
        />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: colors.background }]} edges={["top"]}>
      <ScreenHeader title="My Health Records" showBack={false} centerTitle />
      <ScrollView
        contentContainerStyle={styles.scroll}
        refreshControl={
          <RefreshControl
            refreshing={isRefetching}
            onRefresh={refetch}
            tintColor={colors.primaryTeal}
          />
        }
      >
        {ROWS.map((row) => (
          <Pressable
            key={row.key}
            style={[styles.card, colors.shadows.card, { backgroundColor: colors.white }]}
            onPress={() =>
              showToast(
                `${row.title}: ${String(counts?.[row.key] ?? 0).padStart(2, "0")} records`,
                "info"
              )
            }
          >
            <View style={[styles.iconBox, { backgroundColor: row.bg }]}>
              <Ionicons
                name={row.icon as keyof typeof Ionicons.glyphMap}
                size={24}
                color={row.color}
              />
            </View>
            <View style={styles.center}>
              <Text style={[styles.title, { color: colors.textPrimary }]}>{row.title}</Text>
              <Text style={[styles.count, { color: colors.textSecondary }]}>
                {String(counts?.[row.key] ?? 0).padStart(2, "0")} Records
              </Text>
            </View>
            <Ionicons name="chevron-forward" size={22} color={colors.textSecondary} />
          </Pressable>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  scroll: { padding: 16, gap: 12 },
  card: {
    flexDirection: "row",
    alignItems: "center",
    borderRadius: 16,
    padding: 16,
    gap: 14,
    marginBottom: 12,
  },
  iconBox: {
    width: 48,
    height: 48,
    borderRadius: 12,
    alignItems: "center",
    justifyContent: "center",
  },
  center: { flex: 1 },
  title: { fontFamily: "Poppins_700Bold", fontSize: 16 },
  count: {
    fontFamily: "Poppins_400Regular",
    fontSize: 13,
    marginTop: 2,
  },
});
