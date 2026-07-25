import Constants from "expo-constants";
import { Platform } from "react-native";

const extra = Constants.expoConfig?.extra as { apiUrl?: string } | undefined;

/**
 * API base URL from .env (EXPO_PUBLIC_API_URL).
 * After changing .env you MUST restart: npx expo start -c
 */
export const API_URL =
  process.env.EXPO_PUBLIC_API_URL ??
  extra?.apiUrl ??
  (__DEV__ && Platform.OS === "android" && !Constants.isDevice
    ? "http://10.0.2.2:5000"
    : "http://localhost:5000");

export const STORAGE_KEYS = {
  token: "token",
  user: "@pms/user",
  readNotifications: "@pms/read_notifications",
} as const;
