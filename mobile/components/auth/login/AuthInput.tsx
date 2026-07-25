import { memo, useState } from "react";
import {
  StyleSheet,
  Text,
  TextInput,
  View,
  type TextInputProps,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";

type Theme = "blue" | "red";

const THEME = {
  blue: { primary: "#2563EB", icon: "#9CA3AF" },
  red: { primary: "#B91C1C", icon: "#F87171" },
};

type Props = TextInputProps & {
  label: string;
  icon: keyof typeof Ionicons.glyphMap;
  theme?: Theme;
};

function AuthInputInner({
  label,
  icon,
  theme = "blue",
  ...inputProps
}: Props) {
  const [focused, setFocused] = useState(false);
  const colors = THEME[theme];

  return (
    <View style={styles.wrap}>
      {label ? <Text style={styles.label}>{label}</Text> : null}
      <View
        style={[
          styles.inputRow,
          focused && { borderColor: colors.primary, borderWidth: 2 },
        ]}
      >
        <Ionicons name={icon} size={18} color={colors.icon} style={styles.leftIcon} />
        <TextInput
          {...inputProps}
          style={styles.input}
          placeholderTextColor="#D1D5DB"
          onFocus={(e) => {
            setFocused(true);
            inputProps.onFocus?.(e);
          }}
          onBlur={(e) => {
            setFocused(false);
            inputProps.onBlur?.(e);
          }}
        />
      </View>
    </View>
  );
}

export const AuthInput = memo(AuthInputInner);

const styles = StyleSheet.create({
  wrap: { marginBottom: 16 },
  label: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 14,
    color: "#1F2937",
    marginBottom: 8,
  },
  inputRow: {
    flexDirection: "row",
    alignItems: "center",
    borderWidth: 1,
    borderColor: "#E5E7EB",
    borderRadius: 12,
    backgroundColor: "#fff",
    paddingHorizontal: 12,
    minHeight: 48,
  },
  leftIcon: { marginRight: 8 },
  input: {
    flex: 1,
    fontFamily: "Poppins_400Regular",
    fontSize: 15,
    color: "#111827",
    paddingVertical: 12,
  },
});
