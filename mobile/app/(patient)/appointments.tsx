import { useCallback, useState } from "react";
import { FlatList, Pressable, RefreshControl, StyleSheet, Text, View } from "react-native";
import { router } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { useMyAppointments } from "@/hooks/usePatientAppointments";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { AppointmentCard } from "@/components/cards/AppointmentCard";
import { ScreenLoader } from "@/components/animations/ScreenLoader";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { PrimaryButton } from "@/components/ui/PrimaryButton";
import { useColors } from "@/hooks/useColors";
import type { Appointment } from "@/types/domain";

const TABS = [
  { key: "upcoming", label: "Upcoming" },
  { key: "completed", label: "Completed" },
  { key: "cancelled", label: "Cancelled" },
] as const;

export default function MyAppointmentsScreen() {
  const colors = useColors();
  const [tab, setTab] = useState<(typeof TABS)[number]["key"]>("upcoming");
  const { data = [], isLoading, error, refetch, isRefetching } = useMyAppointments(tab);

  const renderItem = useCallback(
    ({ item }: { item: Appointment }) => (
      <AppointmentCard
        appointment={item}
        showBadge={tab === "upcoming"}
        onPress={() =>
          router.push({
            pathname: "/(patient)/appointment-detail",
            params: { id: String(item.id) },
          })
        }
      />
    ),
    [tab]
  );

  if (isLoading) {
    return <ScreenLoader message="Loading appointments..." />;
  }

  if (error) {
    return (
      <SafeAreaView style={[styles.safe, { backgroundColor: colors.background }]} edges={["top"]}>
        <ScreenHeader title="My Appointments" showBack={false} />
        <ErrorState
          message={error instanceof Error ? error.message : "Failed to load appointments"}
          onRetry={() => refetch()}
        />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: colors.background }]} edges={["top"]}>
      <ScreenHeader title="My Appointments" showBack={false} />

      <View style={styles.tabs}>
        {TABS.map((t) => (
          <Pressable key={t.key} onPress={() => setTab(t.key)} style={styles.tabBtn}>
            <Text
              style={[
                styles.tabText,
                { color: colors.textSecondary },
                tab === t.key && { color: colors.primaryTeal },
              ]}
            >
              {t.label}
            </Text>
            {tab === t.key ? (
              <View style={[styles.underline, { backgroundColor: colors.primaryTeal }]} />
            ) : null}
          </Pressable>
        ))}
      </View>

      <FlatList
        data={data}
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
          <EmptyState
            icon="calendar-outline"
            title={`No ${tab} appointments`}
            message="Book a new appointment to get started."
          />
        }
      />

      <View style={[styles.footer, { backgroundColor: colors.background }]}>
        <PrimaryButton title="Book New Appointment" onPress={() => router.push("/doctors")} />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  tabs: { flexDirection: "row", paddingHorizontal: 16, marginBottom: 8 },
  tabBtn: { flex: 1, alignItems: "center", paddingVertical: 10 },
  tabText: { fontFamily: "Poppins_600SemiBold", fontSize: 14 },
  underline: {
    marginTop: 6,
    height: 3,
    width: "60%",
    borderRadius: 2,
  },
  list: { paddingTop: 8, paddingBottom: 100 },
  footer: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    paddingBottom: 16,
  },
});
