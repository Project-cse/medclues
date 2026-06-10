import "react-native-reanimated";
import "../global.css";
import { useEffect, useState } from "react";
import { Stack, router } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { StatusBar } from "expo-status-bar";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import {
  useFonts,
  Poppins_400Regular,
  Poppins_600SemiBold,
  Poppins_700Bold,
} from "@expo-google-fonts/poppins";
import { QueryProvider } from "@/providers/QueryProvider";
import { ToastProvider } from "@/providers/ToastProvider";
import { useAuthStore } from "@/store/authStore";
import { useThemeStore } from "@/store/themeStore";
import { setUnauthorizedHandler } from "@/utils/session";
import { OfflineBanner } from "@/components/ui/OfflineBanner";
import { API_URL } from "@/constants/config";

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const hydrate = useAuthStore((s) => s.hydrate);
  const isHydrated = useAuthStore((s) => s.isHydrated);
  const isDarkMode = useThemeStore((s) => s.isDarkMode);
  const [fontsLoaded] = useFonts({
    Poppins_400Regular,
    Poppins_600SemiBold,
    Poppins_700Bold,
  });

  useEffect(() => {
    setUnauthorizedHandler(() => {
      router.replace("/(auth)/login");
    });
  }, []);

  useEffect(() => {
    hydrate().finally(() => {
      if (fontsLoaded) SplashScreen.hideAsync();
    });
  }, [hydrate, fontsLoaded]);

  if (!isHydrated || !fontsLoaded) {
    return null;
  }

  return (
    <GestureHandlerRootView
      style={{
        flex: 1,
        backgroundColor: isDarkMode ? "#0F172A" : "#F0F4F8",
      }}
    >
      <QueryProvider>
        <ToastProvider>
          <StatusBar style={isDarkMode ? "light" : "dark"} />
          <OfflineBanner apiBase={API_URL} />
          <Stack screenOptions={{ headerShown: false }}>
            <Stack.Screen name="index" />
            <Stack.Screen name="(auth)" />
            <Stack.Screen name="(patient)" />
            <Stack.Screen name="(doctor)" />
            <Stack.Screen name="(dean)" />
            <Stack.Screen name="(admin)" />
            <Stack.Screen name="(tabs)" />
            <Stack.Screen name="hospitals/index" />
            <Stack.Screen name="doctors/index" />
            <Stack.Screen name="doctors/[id]" />
            <Stack.Screen name="labs/index" />
            <Stack.Screen name="labs/[id]" />
            <Stack.Screen name="blood-banks/[id]" />
            <Stack.Screen name="book-appointment" />
            <Stack.Screen name="payment" />
            <Stack.Screen name="payment-success" />
            <Stack.Screen name="emergency" />
          </Stack>
        </ToastProvider>
      </QueryProvider>
    </GestureHandlerRootView>
  );
}
