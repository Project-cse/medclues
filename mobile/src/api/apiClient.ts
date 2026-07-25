import axios, {
  AxiosError,
  AxiosResponse,
  InternalAxiosRequestConfig,
} from "axios";
import * as SecureStore from "expo-secure-store";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { BASE_URL } from "@/src/config";
import { STORAGE_KEYS } from "@/constants/config";
import { useAuthStore } from "@/store/authStore";
import { triggerUnauthorized } from "@/utils/session";
import { apiToast } from "@/src/utils/toastBridge";

const apiClient = axios.create({
  baseURL: BASE_URL,
  timeout: 30000,
  headers: { "Content-Type": "application/json" },
});

async function readToken(): Promise<string | null> {
  try {
    return await SecureStore.getItemAsync(STORAGE_KEYS.token);
  } catch {
    return AsyncStorage.getItem(STORAGE_KEYS.token);
  }
}

apiClient.interceptors.request.use(async (config: InternalAxiosRequestConfig) => {
  const storeToken = useAuthStore.getState().token;
  const token = storeToken ?? (await readToken());
  if (token) {
    config.headers.set("Authorization", `Bearer ${token}`);
    config.headers.set("token", token);
  }
  return config;
});

apiClient.interceptors.response.use(
  (response: AxiosResponse) => response,
  async (error: AxiosError<{ message?: string; detail?: string }>) => {
    if (error.response?.status === 401) {
      try {
        await SecureStore.deleteItemAsync(STORAGE_KEYS.token);
      } catch {
        /* ignore */
      }
      await AsyncStorage.removeItem(STORAGE_KEYS.token);
      await useAuthStore.getState().clearAuth();
      triggerUnauthorized();
    }

    let message =
      error.response?.data?.message ??
      error.response?.data?.detail ??
      error.message ??
      "Request failed";

    if (error.message === "Network Error" || error.code === "ERR_NETWORK") {
      message = `Cannot reach server at ${BASE_URL}. Start FastAPI and check mobile/.env IP.`;
      apiToast(message, "error");
    }

    return Promise.reject(new Error(message));
  }
);

export default apiClient;
