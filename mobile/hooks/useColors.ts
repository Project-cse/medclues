import { useMemo } from "react";
import { colors as lightColors, shadows as lightShadows } from "@/constants/theme";
import { useAppTheme } from "@/hooks/useAppTheme";

/** Theme-aware palette for patient UI (light + dark). */
export function useColors() {
  const { theme, isDarkMode } = useAppTheme();

  return useMemo(
    () => ({
      ...lightColors,
      background: theme.background,
      white: theme.surface,
      surface: theme.surface,
      textPrimary: theme.text,
      textSecondary: theme.textSecondary,
      border: theme.border,
      card: theme.card,
      primaryTeal: theme.primary,
      red: theme.red,
      green: theme.green,
      navy: isDarkMode ? "#0F172A" : lightColors.navy,
      navyHero: isDarkMode ? "#1E293B" : lightColors.navyHero,
      pillBlueBg: isDarkMode ? "#1E3A5F" : lightColors.pillBlueBg,
      pillTealBg: isDarkMode ? "#134E4A" : lightColors.pillTealBg,
      specCircleBg: isDarkMode ? "#1E3A5F" : "#E0F2FE",
      specCircleFill: isDarkMode ? "#0EA5E9" : "#57D2E8",
      iconCircleBg: isDarkMode ? "#334155" : "#EFF6FF",
      shadows: isDarkMode
        ? {
            card: {
              shadowColor: "#000",
              shadowOffset: { width: 0, height: 4 },
              shadowOpacity: 0.35,
              shadowRadius: 12,
              elevation: 6,
            },
            tabBar: lightShadows.tabBar,
          }
        : lightShadows,
      isDarkMode,
    }),
    [theme, isDarkMode]
  );
}
