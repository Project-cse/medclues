import { useQuery } from "@tanstack/react-query";
import { getAllAppointments, getTodayAppointments } from "@/services/staffApi";
import { useAuth } from "@/hooks/useAuth";

export function useAppointments() {
  const { isAuthenticated } = useAuth();

  return useQuery({
    queryKey: ["appointments", "all"],
    queryFn: getAllAppointments,
    enabled: isAuthenticated,
  });
}

export function useTodayAppointments() {
  const { isAuthenticated } = useAuth();

  return useQuery({
    queryKey: ["appointments", "today"],
    queryFn: getTodayAppointments,
    enabled: isAuthenticated,
  });
}
