import {
  ActivityIndicator,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  type StyleProp,
  type ViewStyle,
} from "react-native";

type Variant = "blue" | "red";

const COLORS: Record<Variant, { bg: string; pressed: string }> = {
  blue: { bg: "#111827", pressed: "#0F172A" },
  red: { bg: "#111827", pressed: "#0F172A" },
};

type Props = {
  label?: string;
  onPress: () => void;
  loading?: boolean;
  disabled?: boolean;
  variant?: Variant;
  style?: StyleProp<ViewStyle>;
};

/** Solid full-width sign-in box (always visible on Android/iOS) */
export function SignInButton({
  label = "Sign In",
  onPress,
  loading,
  disabled,
  variant = "blue",
  style,
}: Props) {
  const colors = COLORS[variant];

  return (
    <View style={[styles.wrap, style]} collapsable={false}>
      <TouchableOpacity
        onPress={onPress}
        disabled={disabled || loading}
        activeOpacity={0.88}
        accessibilityRole="button"
        accessibilityLabel={label}
        style={[
          styles.box,
          { backgroundColor: colors.bg },
          (disabled || loading) && styles.disabled,
        ]}
      >
        {loading ? (
          <ActivityIndicator color="#FFFFFF" size="small" />
        ) : (
          <Text style={styles.label}>{label}</Text>
        )}
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    width: "100%",
    marginTop: 20,
    marginBottom: 8,
  },
  box: {
    width: "100%",
    height: 54,
    borderRadius: 12,
    alignItems: "center",
    justifyContent: "center",
    elevation: 4,
    shadowColor: "#000000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
  },
  disabled: {
    opacity: 0.65,
  },
  label: {
    fontFamily: "Poppins_700Bold",
    fontSize: 17,
    color: "#FFFFFF",
    letterSpacing: 0.3,
  },
});
