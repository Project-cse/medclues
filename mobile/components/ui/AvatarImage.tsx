import { View, StyleSheet } from "react-native";
import { Image } from "expo-image";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/constants/theme";

export function AvatarImage({
  uri,
  size = 56,
  borderColor = colors.primaryTeal,
}: {
  uri?: string | null;
  size?: number;
  borderColor?: string;
}) {
  const radius = size / 2;
  if (uri) {
    return (
      <Image
        source={{ uri }}
        style={{
          width: size,
          height: size,
          borderRadius: radius,
          borderWidth: 2,
          borderColor,
        }}
        contentFit="cover"
      />
    );
  }
  return (
    <View
      style={[
        styles.placeholder,
        { width: size, height: size, borderRadius: radius, borderColor },
      ]}
    >
      <Ionicons name="person" size={size * 0.45} color={colors.primaryTeal} />
    </View>
  );
}

const styles = StyleSheet.create({
  placeholder: {
    borderWidth: 2,
    backgroundColor: "#E0F2FE",
    alignItems: "center",
    justifyContent: "center",
  },
});
