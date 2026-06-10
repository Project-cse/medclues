/** MediChain+ official brand — blue & white */
export const brand = {
  blue: "#1565C0",
  blueDark: "#0D47A1",
  blueLight: "#E3F2FD",
  cyan: "#57D2E8",
  navy: "#011A4D",
  white: "#FFFFFF",
  background: "#F5F9FC",
  surface: "#FFFFFF",
  textPrimary: "#0F172A",
  textSecondary: "#64748B",
  border: "#E2E8F0",
} as const;

/** @deprecated Use `brand` — kept for existing imports */
export const ubuntu = {
  orange: brand.blue,
  orangeDark: brand.blueDark,
  orangeLight: brand.blueLight,
  aubergine: brand.navy,
  aubergineDark: brand.blueDark,
  aubergineLight: brand.blueLight,
  warmWhite: brand.background,
  warmGrey: brand.textSecondary,
  textDark: brand.textPrimary,
} as const;

export const colors = {
  primary: brand.blue,
  primaryTeal: brand.cyan,
  primaryBlue: brand.blueDark,
  green: "#10B981",
  orange: "#F97316",
  red: "#EF4444",
  background: brand.background,
  white: brand.white,
  textPrimary: brand.textPrimary,
  textSecondary: brand.textSecondary,
  star: "#F59E0B",
  navy: brand.navy,
  navyHero: brand.blueDark,
  border: brand.border,
  verified: brand.blue,
  pillGreenBg: "#D1FAE5",
  pillBlueBg: brand.blueLight,
  pillOrangeBg: "#FFEDD5",
  pillTealBg: "#E0F7FA",
} as const;

export const spacing = {
  screenX: 16,
  cardRadius: 16,
  buttonRadius: 12,
} as const;

export const typography = {
  appName: { fontSize: 20, fontWeight: "700" as const },
  screenTitle: { fontSize: 22, fontWeight: "700" as const },
  cardTitle: { fontSize: 16, fontWeight: "600" as const },
  subtitle: { fontSize: 13, fontWeight: "400" as const },
  greetingLarge: { fontSize: 26, fontWeight: "700" as const },
};

export const shadows = {
  card: {
    shadowColor: brand.navy,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.08,
    shadowRadius: 14,
    elevation: 5,
  },
  tabBar: {
    shadowColor: brand.navy,
    shadowOffset: { width: 0, height: -4 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 12,
  },
};
