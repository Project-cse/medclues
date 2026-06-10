import { StyleSheet, TextInput, View, Pressable } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { spacing } from "@/constants/theme";
import { useColors } from "@/hooks/useColors";

interface SearchBarProps {
  placeholder: string;
  value?: string;
  onChangeText?: (t: string) => void;
  onFilterPress?: () => void;
  leftIcon?: keyof typeof Ionicons.glyphMap;
}

export function SearchBar({
  placeholder,
  value,
  onChangeText,
  onFilterPress,
  leftIcon = "search",
}: SearchBarProps) {
  const colors = useColors();

  return (
    <View style={[styles.wrap, colors.shadows.card, { backgroundColor: colors.white }]}>
      <Ionicons name={leftIcon} size={20} color={colors.textSecondary} />
      <TextInput
        style={[styles.input, { color: colors.textPrimary }]}
        placeholder={placeholder}
        placeholderTextColor={colors.textSecondary}
        value={value}
        onChangeText={onChangeText}
      />
      {onFilterPress ? (
        <Pressable onPress={onFilterPress} hitSlop={8}>
          <Ionicons name="options-outline" size={22} color={colors.primaryTeal} />
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: "row",
    alignItems: "center",
    marginHorizontal: spacing.screenX,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 999,
    gap: 10,
  },
  input: {
    flex: 1,
    fontSize: 14,
    padding: 0,
  },
});
