import { useQuery, useQueryClient } from "@tanstack/react-query";
import { authService } from "@/services/auth";
import { doctorService } from "@/services/doctors";
import { hospitalService } from "@/services/hospitals";
import { appointmentService } from "@/services/appointments";
import { recordsService } from "@/services/records";
import { useAuth } from "@/hooks/useAuth";

const REFRESH_MS = 30_000;

function patientEnabled(role: string | null | undefined, isAuthenticated: boolean) {
  return isAuthenticated && role === "patient";
}

export function usePatientData() {
  const { isAuthenticated, user } = useAuth();
  const enabled = patientEnabled(user?.role, isAuthenticated);

  const dashboard = useQuery({
    queryKey: ["patient", "dashboard"],
    queryFn: async () => {
      const [profile, appointments, recordCounts, doctors, hospitals] =
        await Promise.all([
          authService.getMe().catch(() => null),
          appointmentService.getMyAppointments().catch(() => []),
          recordsService.getCounts().catch(() => null),
          doctorService.getTopDoctors(8).catch(() => []),
          hospitalService.getAll().catch(() => []),
        ]);
      return { profile, appointments, recordCounts, doctors, hospitals };
    },
    enabled,
    refetchInterval: REFRESH_MS,
    staleTime: 10_000,
  });

  return {
    dashboard,
    isLoading: dashboard.isLoading && !dashboard.data,
    isRefetching: dashboard.isRefetching,
    error: dashboard.error,
    refetchAll: () => dashboard.refetch(),
  };
}

export async function prefetchPatientData(queryClient: ReturnType<typeof useQueryClient>) {
  await queryClient.prefetchQuery({
    queryKey: ["patient", "dashboard"],
    queryFn: async () => {
      const [profile, appointments] = await Promise.all([
        authService.getMe(),
        appointmentService.getMyAppointments(),
      ]);
      return { profile, appointments };
    },
  });
}
