import { Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { panelColors, panelShadow } from "@/constants/panelTheme";

interface ReportListItemProps {
  title: string;
  subtitle: string;
  icon?: keyof typeof Ionicons.glyphMap;
  iconColor?: string;
  onPress?: () => void;
}

export function ReportListItem({
  title,
  subtitle,
  icon = "document-text-outline",
  iconColor = panelColors.primary,
  onPress,
}: ReportListItemProps) {
  return (
    <Pressable style={[styles.row, panelShadow]} onPress={onPress}>
      <View style={[styles.iconWrap, { backgroundColor: `${iconColor}18` }]}>
        <Ionicons name={icon} size={22} color={iconColor} />
      </View>
      <View style={styles.text}>
        <Text style={styles.title}>{title}</Text>
        <Text style={styles.sub}>{subtitle}</Text>
      </View>
      <Ionicons name="chevron-forward" size={20} color={panelColors.textSecondary} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: panelColors.card,
    borderRadius: 12,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: panelColors.border,
    gap: 12,
  },
  iconWrap: {
    width: 44,
    height: 44,
    borderRadius: 12,
    alignItems: "center",
    justifyContent: "center",
  },
  text: { flex: 1 },
  title: { fontFamily: "Poppins_600SemiBold", fontSize: 15, color: panelColors.textPrimary },
  sub: { fontFamily: "Poppins_400Regular", fontSize: 12, color: panelColors.textSecondary, marginTop: 2 },
});
