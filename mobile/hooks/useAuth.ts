import { useAuthStore, selectIsAuthenticated } from "@/store/authStore";

export function useAuth() {
  const token = useAuthStore((s) => s.token);
  const user = useAuthStore((s) => s.user);
  const isHydrated = useAuthStore((s) => s.isHydrated);
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  const setAuth = useAuthStore((s) => s.setAuth);
  const clearAuth = useAuthStore((s) => s.clearAuth);
  const hydrate = useAuthStore((s) => s.hydrate);

  return {
    token,
    user,
    role: user?.role ?? null,
    email: user?.email ?? null,
    name: user?.name ?? null,
    branchId: user?.branch_id ?? null,
    isHydrated,
    isAuthenticated,
    setAuth,
    clearAuth,
    hydrate,
  };
}
