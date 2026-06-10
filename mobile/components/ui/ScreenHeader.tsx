import { Pressable, StyleSheet, Text, View } from "react-native";
import { router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { typography } from "@/constants/theme";
import { useColors } from "@/hooks/useColors";

interface ScreenHeaderProps {
  title: string;
  showBack?: boolean;
  onBack?: () => void;
  rightIcon?: keyof typeof Ionicons.glyphMap;
  onRightPress?: () => void;
  centerTitle?: boolean;
}

export function ScreenHeader({
  title,
  showBack = true,
  onBack,
  rightIcon,
  onRightPress,
  centerTitle = false,
}: ScreenHeaderProps) {
  const colors = useColors();

  return (
    <View style={styles.row}>
      {showBack ? (
        <Pressable onPress={onBack ?? (() => router.back())} hitSlop={12} style={styles.side}>
          <Ionicons name="arrow-back" size={24} color={colors.textPrimary} />
        </Pressable>
      ) : (
        <View style={styles.side} />
      )}
      <Text
        style={[styles.title, { color: colors.textPrimary }, centerTitle && styles.titleCenter]}
        numberOfLines={1}
      >
        {title}
      </Text>
      {rightIcon ? (
        <Pressable onPress={onRightPress} hitSlop={12} style={styles.side}>
          <Ionicons name={rightIcon} size={24} color={colors.textPrimary} />
        </Pressable>
      ) : (
        <View style={styles.side} />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  side: { width: 40, alignItems: "center" },
  title: {
    flex: 1,
    ...typography.screenTitle,
    textAlign: "left",
  },
  titleCenter: { textAlign: "center" },
});
