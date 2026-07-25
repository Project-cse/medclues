import { StyleSheet, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useColors } from "@/hooks/useColors";

type Variant = "calendar" | "hospital" | "doctor" | "status";

const ICONS: Record<Variant, keyof typeof Ionicons.glyphMap> = {
  calendar: "calendar",
  hospital: "business",
  doctor: "medical",
  status: "checkmark-circle",
};

export function MedicalMetaIcon({ variant, size = 14 }: { variant: Variant; size?: number }) {
  const colors = useColors();
  const box = size + 8;

  return (
    <View style={[styles.wrap, { width: box, height: box, backgroundColor: colors.iconCircleBg }]}>
      <Ionicons name={ICONS[variant]} size={size} color={colors.primaryTeal} />
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    borderRadius: 999,
    alignItems: "center",
    justifyContent: "center",
  },
});
