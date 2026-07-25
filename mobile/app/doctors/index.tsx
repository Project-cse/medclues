import { useCallback, useState } from "react";
import { FlatList, RefreshControl, StyleSheet, View } from "react-native";
import { useLocalSearchParams } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { useDoctors } from "@/hooks/useDoctors";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { SearchBar } from "@/components/ui/SearchBar";
import { DoctorListCard } from "@/components/cards/DoctorListCard";
import { ScreenLoader } from "@/components/animations/ScreenLoader";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { useColors } from "@/hooks/useColors";
import type { Doctor } from "@/types/domain";

export default function AllDoctorsScreen() {
  const colors = useColors();
  const params = useLocalSearchParams<{ search?: string; speciality?: string }>();
  const [search, setSearch] = useState(params.search ?? "");
  const speciality = params.speciality;
  const screenTitle = speciality
    ? `${speciality.charAt(0).toUpperCase()}${speciality.slice(1)} Doctors`
    : "All Doctors";

  const { data: doctors = [], isLoading, error, refetch, isRefetching } = useDoctors({
    search,
    speciality,
  });

  const renderItem = useCallback(
    ({ item, index }: { item: Doctor; index: number }) => (
      <DoctorListCard doctor={item} index={index} />
    ),
    []
  );

  if (isLoading) {
    return <ScreenLoader message="Loading doctors..." />;
  }

  if (error) {
    return (
      <SafeAreaView style={[styles.safe, { backgroundColor: colors.background }]} edges={["top"]}>
        <ScreenHeader title={screenTitle} />
        <ErrorState
          message={error instanceof Error ? error.message : "Failed to load doctors"}
          onRetry={() => refetch()}
        />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safe} edges={["top"]}>
      <ScreenHeader title={screenTitle} rightIcon="options-outline" />
      <SearchBar placeholder="Search doctors..." value={search} onChangeText={setSearch} />
      <View style={{ height: 12 }} />
      <FlatList
        data={doctors}
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
          <EmptyState icon="medical-outline" title="No doctors found" />
        }
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  list: { paddingBottom: 24 },
});
