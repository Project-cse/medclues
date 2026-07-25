import { StyleSheet, Text, View } from "react-native";
import { panelColors, panelShadow } from "@/constants/panelTheme";

interface StatCardPanelProps {
  label: string;
  value: string | number;
  change?: string;
  positive?: boolean;
  accent?: string;
}

export function StatCardPanel({
  label,
  value,
  change,
  positive = true,
  accent = panelColors.primary,
}: StatCardPanelProps) {
  return (
    <View style={[styles.card, panelShadow]}>
      <Text style={[styles.value, { color: accent }]}>{value}</Text>
      <Text style={styles.label}>{label}</Text>
      {change ? (
        <Text style={[styles.change, { color: positive ? panelColors.completed : panelColors.cancelled }]}>
          {change}
        </Text>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flex: 1,
    minWidth: "45%",
    backgroundColor: panelColors.card,
    borderRadius: 12,
    padding: 14,
    borderWidth: 1,
    borderColor: panelColors.border,
  },
  value: {
    fontFamily: "Poppins_700Bold",
    fontSize: 22,
  },
  label: {
    fontFamily: "Poppins_400Regular",
    fontSize: 12,
    color: panelColors.textSecondary,
    marginTop: 4,
  },
  change: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 11,
    marginTop: 6,
  },
});
