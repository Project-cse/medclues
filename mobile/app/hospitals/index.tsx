import { useCallback, useState } from "react";
import { FlatList, RefreshControl, StyleSheet, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useHospitals } from "@/hooks/useHospitals";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { SearchBar } from "@/components/ui/SearchBar";
import { HospitalCard } from "@/components/cards/HospitalCard";
import { ScreenLoader } from "@/components/animations/ScreenLoader";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { colors } from "@/constants/theme";
import type { Hospital } from "@/types/domain";

export default function HospitalsScreen() {
  const [search, setSearch] = useState("");
  const { data: hospitals = [], isLoading, error, refetch, isRefetching } = useHospitals({
    search,
  });

  const renderItem = useCallback(
    ({ item }: { item: Hospital }) => <HospitalCard hospital={item} />,
    []
  );

  if (isLoading) {
    return <ScreenLoader message="Loading hospitals..." />;
  }

  if (error) {
    return (
      <SafeAreaView style={styles.safe} edges={["top"]}>
        <ScreenHeader title="Hospitals" />
        <ErrorState
          message={error instanceof Error ? error.message : "Failed to load hospitals"}
          onRetry={() => refetch()}
        />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safe} edges={["top"]}>
      <ScreenHeader title="Hospitals" rightIcon="options-outline" />
      <SearchBar
        placeholder="Search hospitals..."
        value={search}
        onChangeText={setSearch}
        onFilterPress={() => {}}
      />
      <View style={{ height: 12 }} />
      <FlatList
        data={hospitals}
        keyExtractor={(item) => String(item.id)}
        renderItem={renderItem}
        refreshControl={
          <RefreshControl
            refreshing={isRefetching}
            onRefresh={refetch}
            tintColor={colors.primaryTeal}
          />
        }
        contentContainerStyle={styles.list}
        ListEmptyComponent={
          <EmptyState icon="business-outline" title="No hospitals found" message="Try a different search." />
        }
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  list: { paddingBottom: 24 },
});
