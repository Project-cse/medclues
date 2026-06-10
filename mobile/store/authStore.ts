import AsyncStorage from "@react-native-async-storage/async-storage";
import * as SecureStore from "expo-secure-store";
import { create } from "zustand";
import { STORAGE_KEYS } from "@/constants/config";
import type { User } from "@/types/api";

interface AuthState {
  token: string | null;
  user: User | null;
  isHydrated: boolean;
  hydrate: () => Promise<void>;
  setAuth: (token: string, user: User) => Promise<void>;
  updateUser: (partial: Partial<User>) => Promise<void>;
  clearAuth: () => Promise<void>;
}

async function getToken(): Promise<string | null> {
  try {
    return await SecureStore.getItemAsync(STORAGE_KEYS.token);
  } catch {
    return AsyncStorage.getItem(STORAGE_KEYS.token);
  }
}

async function setToken(token: string): Promise<void> {
  try {
    await SecureStore.setItemAsync(STORAGE_KEYS.token, token);
  } catch {
    await AsyncStorage.setItem(STORAGE_KEYS.token, token);
  }
}

async function removeToken(): Promise<void> {
  try {
    await SecureStore.deleteItemAsync(STORAGE_KEYS.token);
  } catch {
    /* ignore */
  }
  await AsyncStorage.removeItem(STORAGE_KEYS.token);
}

export const useAuthStore = create<AuthState>((set) => ({
  token: null,
  user: null,
  isHydrated: false,

  hydrate: async () => {
    try {
      const [token, userJson] = await Promise.all([
        getToken(),
        AsyncStorage.getItem(STORAGE_KEYS.user),
      ]);

      set({
        token,
        user: userJson ? (JSON.parse(userJson) as User) : null,
        isHydrated: true,
      });
    } catch {
      set({ isHydrated: true });
    }
  },

  setAuth: async (token, user) => {
    await Promise.all([
      setToken(token),
      AsyncStorage.setItem(STORAGE_KEYS.user, JSON.stringify(user)),
    ]);
    set({ token, user });
  },

  updateUser: async (partial) => {
    const current = useAuthStore.getState().user;
    if (!current) return;
    const next = { ...current, ...partial };
    await AsyncStorage.setItem(STORAGE_KEYS.user, JSON.stringify(next));
    set({ user: next });
  },

  clearAuth: async () => {
    await Promise.all([
      removeToken(),
      AsyncStorage.removeItem(STORAGE_KEYS.user),
    ]);
    set({ token: null, user: null });
  },
}));

export const selectIsAuthenticated = (state: AuthState) => Boolean(state.token);
export const selectUserRole = (state: AuthState) => state.user?.role ?? null;
