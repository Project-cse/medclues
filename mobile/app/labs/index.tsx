import { useEffect, useState } from "react";
import { useLocalSearchParams } from "expo-router";
import {
  FlatList,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useLabs } from "@/hooks/useLabs";
import { useBloodBanks } from "@/hooks/useBloodBanks";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { SearchBar } from "@/components/ui/SearchBar";
import { LabCard } from "@/components/cards/LabCard";
import { BloodBankCard } from "@/components/cards/BloodBankCard";
import { ScreenLoader } from "@/components/animations/ScreenLoader";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { colors } from "@/constants/theme";

type TabMode = "labs" | "blood";

export default function LabsAndBloodBanksScreen() {
  const { tab } = useLocalSearchParams<{ tab?: string }>();
  const [mode, setMode] = useState<TabMode>("labs");

  useEffect(() => {
    if (tab === "blood" || tab === "bloodbanks") {
      setMode("blood");
    }
  }, [tab]);
  const [search, setSearch] = useState("");
  const [openOnly, setOpenOnly] = useState(false);

  const labsQuery = useLabs({ search, openNow: openOnly });
  const banksQuery = useBloodBanks({ search });

  const active = mode === "labs" ? labsQuery : banksQuery;

  if (active.isLoading) {
    return <ScreenLoader message="Loading labs..." />;
  }

  if (active.error) {
    return (
      <SafeAreaView style={styles.safe} edges={["top"]}>
        <ScreenHeader title="Labs & Blood Banks" />
        <ErrorState
          message={active.error instanceof Error ? active.error.message : "Failed to load"}
          onRetry={() => active.refetch()}
        />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safe} edges={["top"]}>
      <ScreenHeader title="Labs & Blood Banks" />
      <ScrollView>
        <View style={styles.intro}>
          <Text style={styles.introTitle}>All Labs & Blood Banks</Text>
          <Text style={styles.introSub}>
            Browse our network of trusted, collaborated labs and blood banks.
          </Text>
          <View style={styles.toggleRow}>
            <Pressable
              style={[styles.toggle, mode === "labs" && styles.toggleActive]}
              onPress={() => setMode("labs")}
            >
              <Text style={[styles.toggleText, mode === "labs" && styles.toggleTextActive]}>
                🔬 Labs
              </Text>
            </Pressable>
            <Pressable
              style={[styles.toggle, mode === "blood" && styles.toggleActive]}
              onPress={() => setMode("blood")}
            >
              <Text style={[styles.toggleText, mode === "blood" && styles.toggleTextActive]}>
                🩸 Blood Banks
              </Text>
            </Pressable>
          </View>
        </View>

        <SearchBar
          placeholder={mode === "labs" ? "Search for tests or labs..." : "Search blood banks..."}
          value={search}
          onChangeText={setSearch}
        />

        {mode === "labs" ? (
          <View style={styles.openRow}>
            <Text style={styles.openLabel}>Open Now</Text>
            <Switch
              value={openOnly}
              onValueChange={setOpenOnly}
              trackColor={{ true: colors.primaryTeal }}
            />
          </View>
        ) : null}

        {mode === "labs" ? (
          <FlatList
            data={labsQuery.data ?? []}
            scrollEnabled={false}
            keyExtractor={(item) => String(item.id)}
            renderItem={({ item }) => <LabCard lab={item} />}
            refreshControl={
              <RefreshControl
                refreshing={labsQuery.isRefetching}
                onRefresh={labsQuery.refetch}
                tintColor={colors.primaryTeal}
              />
            }
            ListEmptyComponent={<EmptyState icon="flask-outline" title="No labs found" />}
            contentContainerStyle={styles.list}
          />
        ) : (
          <FlatList
            data={banksQuery.data ?? []}
            scrollEnabled={false}
            keyExtractor={(item) => String(item.id)}
            renderItem={({ item }) => <BloodBankCard bank={item} />}
            refreshControl={
              <RefreshControl
                refreshing={banksQuery.isRefetching}
                onRefresh={banksQuery.refetch}
                tintColor={colors.primaryTeal}
              />
            }
            ListEmptyComponent={<EmptyState icon="water-outline" title="No blood banks found" />}
            contentContainerStyle={styles.list}
          />
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  intro: { paddingHorizontal: 16, paddingBottom: 12 },
  introTitle: { fontFamily: "Poppins_700Bold", fontSize: 22, color: colors.textPrimary },
  introSub: {
    fontFamily: "Poppins_400Regular",
    fontSize: 13,
    color: colors.textSecondary,
    marginTop: 6,
    marginBottom: 14,
  },
  toggleRow: { flexDirection: "row", gap: 10 },
  toggle: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 12,
    backgroundColor: colors.white,
    alignItems: "center",
    borderWidth: 1,
    borderColor: colors.border,
  },
  toggleActive: { backgroundColor: colors.primaryTeal, borderColor: colors.primaryTeal },
  toggleText: { fontFamily: "Poppins_600SemiBold", color: colors.textSecondary },
  toggleTextActive: { color: "#fff" },
  openRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingHorizontal: 16,
    marginVertical: 12,
  },
  openLabel: { fontFamily: "Poppins_600SemiBold", color: colors.textPrimary },
  list: { paddingBottom: 32 },
});
