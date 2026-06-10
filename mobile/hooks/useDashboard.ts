import { useQuery, useQueryClient } from "@tanstack/react-query";
import {
  fetchBillingSummaryCard,
  fetchBranchName,
  fetchDashboardStats,
  fetchNotificationsList,
  fetchRecentPatientsList,
  fetchTodayAppointmentsList,
  fetchTodayScheduleList,
} from "@/services/dashboardApi";
import { markNotificationRead } from "@/services/staffApi";
import { useAuth } from "@/hooks/useAuth";

const REFRESH_MS = 30_000;

export const dashboardQueryKeys = {
  stats: ["dashboard", "stats"] as const,
  appointmentsToday: ["dashboard", "appointments-today"] as const,
  patientsRecent: ["dashboard", "patients-recent"] as const,
  scheduleToday: ["dashboard", "schedule-today"] as const,
  billing: ["dashboard", "billing"] as const,
  notifications: ["dashboard", "notifications"] as const,
  branch: ["dashboard", "branch"] as const,
};

function queryOptions(enabled: boolean) {
  return {
    enabled,
    refetchInterval: REFRESH_MS,
    staleTime: 15_000,
  };
}

export function useDashboardQueries() {
  const { user, isAuthenticated } = useAuth();
  const enabled = isAuthenticated && Boolean(user);

  const stats = useQuery({
    queryKey: dashboardQueryKeys.stats,
    queryFn: fetchDashboardStats,
    ...queryOptions(enabled),
  });

  const appointmentsToday = useQuery({
    queryKey: dashboardQueryKeys.appointmentsToday,
    queryFn: fetchTodayAppointmentsList,
    ...queryOptions(enabled),
  });

  const recentPatients = useQuery({
    queryKey: dashboardQueryKeys.patientsRecent,
    queryFn: fetchRecentPatientsList,
    ...queryOptions(enabled),
  });

  const scheduleToday = useQuery({
    queryKey: dashboardQueryKeys.scheduleToday,
    queryFn: fetchTodayScheduleList,
    ...queryOptions(enabled),
  });

  const billing = useQuery({
    queryKey: dashboardQueryKeys.billing,
    queryFn: fetchBillingSummaryCard,
    ...queryOptions(enabled),
  });

  const notifications = useQuery({
    queryKey: dashboardQueryKeys.notifications,
    queryFn: fetchNotificationsList,
    ...queryOptions(enabled),
  });

  const branch = useQuery({
    queryKey: dashboardQueryKeys.branch,
    queryFn: fetchBranchName,
    ...queryOptions(enabled),
  });

  return {
    stats,
    appointmentsToday,
    recentPatients,
    scheduleToday,
    billing,
    notifications,
    branch,
  };
}

export function useDashboardRefresh() {
  const queryClient = useQueryClient();
  return () =>
    queryClient.invalidateQueries({ queryKey: ["dashboard"] });
}

export function useMarkNotificationRead() {
  const queryClient = useQueryClient();
  return async (id: string) => {
    await markNotificationRead(id);
    await queryClient.invalidateQueries({
      queryKey: dashboardQueryKeys.notifications,
    });
  };
}
