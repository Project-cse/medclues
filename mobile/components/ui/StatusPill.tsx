import { StyleSheet, Text, View } from "react-native";
import { colors } from "@/constants/theme";

type PillVariant = "open" | "verified" | "available" | "upcoming" | "experience";

const VARIANTS: Record<
  PillVariant,
  { label: string; bg: string; color: string }
> = {
  open: { label: "OPEN NOW", bg: colors.pillGreenBg, color: colors.green },
  verified: { label: "VERIFIED", bg: colors.pillBlueBg, color: colors.verified },
  available: { label: "Available", bg: colors.pillGreenBg, color: colors.green },
  upcoming: { label: "Upcoming", bg: colors.pillTealBg, color: colors.primaryTeal },
  experience: { label: "", bg: colors.pillOrangeBg, color: colors.orange },
};

interface StatusPillProps {
  variant: PillVariant;
  label?: string;
}

export function StatusPill({ variant, label }: StatusPillProps) {
  const v = VARIANTS[variant];
  const text = label ?? v.label;
  return (
    <View style={[styles.pill, { backgroundColor: v.bg }]}>
      <Text style={[styles.text, { color: v.color }]}>{text}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 999,
  },
  text: { fontSize: 10, fontWeight: "700", letterSpacing: 0.3 },
});
