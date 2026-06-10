import { useQuery } from "@tanstack/react-query";
import api from "@/services/api";

/** Unread notification count — falls back to 0 if endpoint is unavailable */
export function useUnreadNotificationCount() {
  return useQuery({
    queryKey: ["notifications", "unread-count"],
    queryFn: async () => {
      try {
        const { data } = await api.get<{ count?: number; unread?: number }>(
          "/api/notifications/unread-count"
        );
        return data.count ?? data.unread ?? 0;
      } catch {
        return 0;
      }
    },
    refetchInterval: 60_000,
    staleTime: 30_000,
  });
}
