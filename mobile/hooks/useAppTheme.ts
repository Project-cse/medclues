import { useMemo } from "react";
import { useThemeStore } from "@/store/themeStore";

export const lightTheme = {
  background: "#F0F4F8",
  surface: "#FFFFFF",
  primary: "#0EA5E9",
  text: "#1E293B",
  textSecondary: "#64748B",
  border: "#E2E8F0",
  card: "#FFFFFF",
  tabBar: "#FFFFFF",
  statusBar: "dark" as const,
  red: "#EF4444",
  green: "#10B981",
};

export const darkTheme = {
  background: "#0F172A",
  surface: "#1E293B",
  primary: "#0EA5E9",
  text: "#F8FAFC",
  textSecondary: "#94A3B8",
  border: "#334155",
  card: "#1E293B",
  tabBar: "#1E293B",
  statusBar: "light" as const,
  red: "#F87171",
  green: "#34D399",
};

export function useAppTheme() {
  const isDarkMode = useThemeStore((s) => s.isDarkMode);
  const toggleTheme = useThemeStore((s) => s.toggleTheme);
  const setDarkMode = useThemeStore((s) => s.setDarkMode);

  const theme = useMemo(() => (isDarkMode ? darkTheme : lightTheme), [isDarkMode]);

  return { theme, isDarkMode, toggleTheme, setDarkMode };
}
