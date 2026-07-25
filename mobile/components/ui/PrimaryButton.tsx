import { ActivityIndicator, Pressable, StyleSheet, Text } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { brand, colors } from "@/constants/theme";

interface PrimaryButtonProps {
  title: string;
  onPress: () => void;
  loading?: boolean;
  variant?: "primary" | "teal" | "ubuntu" | "red" | "outline";
  disabled?: boolean;
  fullWidth?: boolean;
}

export function PrimaryButton({
  title,
  onPress,
  loading,
  variant = "primary",
  disabled,
  fullWidth,
}: PrimaryButtonProps) {
  if (variant === "outline") {
    return (
      <Pressable
        onPress={onPress}
        disabled={disabled || loading}
        style={[styles.outline, disabled && styles.disabled]}
      >
        {loading ? (
          <ActivityIndicator color={brand.blue} />
        ) : (
          <Text style={styles.outlineText}>{title}</Text>
        )}
      </Pressable>
    );
  }

  const gradientColors: [string, string] =
    variant === "red"
      ? [colors.red, "#DC2626"]
      : variant === "ubuntu" || variant === "teal" || variant === "primary"
        ? [brand.blue, brand.blueDark]
        : [brand.blue, brand.blueDark];

  return (
    <Pressable
      onPress={onPress}
      disabled={disabled || loading}
      style={[disabled && styles.disabled, fullWidth && styles.fullWidth]}
    >
      <LinearGradient
        colors={gradientColors}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 0 }}
        style={[styles.gradient, fullWidth && styles.gradientFull]}
      >
        {loading ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.text}>{title}</Text>
        )}
      </LinearGradient>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  fullWidth: { width: "100%" },
  gradient: {
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: "center",
    justifyContent: "center",
    marginHorizontal: 16,
  },
  gradientFull: {
    marginHorizontal: 0,
    borderRadius: 14,
    paddingVertical: 15,
  },
  text: { color: "#fff", fontSize: 16, fontWeight: "700" },
  outline: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 12,
    borderWidth: 1.5,
    borderColor: colors.border,
    alignItems: "center",
    backgroundColor: "#fff",
    flex: 1,
  },
  outlineText: { color: colors.textPrimary, fontWeight: "600", fontSize: 13 },
  disabled: { opacity: 0.5 },
});
