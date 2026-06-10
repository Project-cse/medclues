import { useCallback, useMemo, useState } from "react";
import {
  RefreshControl,
  ScrollView,
  StatusBar,
  Text,
  View,
} from "react-native";
import { router } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { DashboardHeader } from "@/components/dashboard/DashboardHeader";
import { StatsCardsRow } from "@/components/dashboard/StatsCardsRow";
import { TodayAppointmentsSection } from "@/components/dashboard/TodayAppointmentsSection";
import { RecentPatientsSection } from "@/components/dashboard/RecentPatientsSection";
import { DoctorScheduleSection } from "@/components/dashboard/DoctorScheduleSection";
import { BillingSummaryCard } from "@/components/dashboard/BillingSummaryCard";
import { NotificationsSheet } from "@/components/dashboard/NotificationsSheet";
import { useAuth } from "@/hooks/useAuth";
import {
  useDashboardQueries,
  useDashboardRefresh,
  useMarkNotificationRead,
} from "@/hooks/useDashboard";
import { canSeeSection } from "@/utils/dashboardPermissions";
import { logout } from "@/services/staffApi";

export default function DashboardScreen() {
  const { user } = useAuth();
  const role = user?.role;
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  const {
    stats,
    appointmentsToday,
    recentPatients,
    scheduleToday,
    billing,
    notifications,
    branch,
  } = useDashboardQueries();

  const refreshAll = useDashboardRefresh();
  const markRead = useMarkNotificationRead();

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await refreshAll();
    setRefreshing(false);
  }, [refreshAll]);

  const unreadCount = useMemo(
    () => (notifications.data ?? []).filter((n) => !n.read).length,
    [notifications.data]
  );

  const showStats = canSeeSection(role, "stats");
  const showAppointments = canSeeSection(role, "appointments");
  const showPatients = canSeeSection(role, "patients");
  const showSchedule = canSeeSection(role, "schedule");
  const showBilling = canSeeSection(role, "billing");

  const statsHiddenKeys = role === "doctor" || role === "nurse" ? ["billing"] : [];

  const isInitialLoading =
    stats.isLoading &&
    appointmentsToday.isLoading &&
    !stats.data &&
    !appointmentsToday.data;

  const handleLogout = async () => {
    await logout();
    router.replace("/");
  };

  return (
    <SafeAreaView className="flex-1 bg-slate-50" edges={["top", "left", "right"]}>
      <StatusBar barStyle="dark-content" backgroundColor="#f8fafc" />

      <ScrollView
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor="#2563EB"
            colors={["#2563EB"]}
          />
        }
        contentContainerClassName="pb-8"
      >
        <DashboardHeader
          name={user?.name ?? "User"}
          role={role}
          branchName={branch.data ?? "Loading branch…"}
          notificationCount={unreadCount}
          onNotificationsPress={() => setNotificationsOpen(true)}
          onProfilePress={handleLogout}
        />

        {showStats ? (
          <View className="mb-6">
            <StatsCardsRow
              stats={stats.data}
              loading={stats.isLoading && !stats.data}
              hiddenKeys={statsHiddenKeys}
            />
          </View>
        ) : null}

        {stats.isError ? (
          <View className="mx-4 mb-4 rounded-xl bg-red-50 p-3">
            <Text className="text-sm text-red-700">
              Could not load stats. Pull to refresh or check your connection.
            </Text>
          </View>
        ) : null}

        {showAppointments ? (
          <TodayAppointmentsSection
            appointments={appointmentsToday.data ?? []}
            loading={appointmentsToday.isLoading && !appointmentsToday.data}
            onViewAll={() => router.push("/(tabs)/appointments")}
          />
        ) : null}

        {showPatients ? (
          <RecentPatientsSection
            patients={recentPatients.data ?? []}
            loading={recentPatients.isLoading && !recentPatients.data}
            onViewAll={() => router.push("/(tabs)/patients")}
          />
        ) : null}

        {showSchedule ? (
          <DoctorScheduleSection
            slots={scheduleToday.data ?? []}
            loading={scheduleToday.isLoading && !scheduleToday.data}
          />
        ) : null}

        {showBilling ? (
          <BillingSummaryCard
            billing={billing.data}
            loading={billing.isLoading && !billing.data}
          />
        ) : null}

        {isInitialLoading ? (
          <Text className="pb-4 text-center text-xs text-slate-400">
            Syncing dashboard…
          </Text>
        ) : null}
      </ScrollView>

      <NotificationsSheet
        visible={notificationsOpen}
        onClose={() => setNotificationsOpen(false)}
        notifications={notifications.data ?? []}
        loading={notifications.isLoading && !notifications.data}
        onMarkRead={(id) => markRead(id)}
      />
    </SafeAreaView>
  );
}
