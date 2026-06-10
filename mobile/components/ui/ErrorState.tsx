import { Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/constants/theme";

export function ErrorState({
  message = "Something went wrong",
  onRetry,
}: {
  message?: string;
  onRetry?: () => void;
}) {
  return (
    <View style={styles.wrap}>
      <Ionicons name="cloud-offline-outline" size={40} color={colors.red} />
      <Text style={styles.title}>Could not load data</Text>
      <Text style={styles.message}>{message}</Text>
      {onRetry ? (
        <Pressable style={styles.btn} onPress={onRetry}>
          <Text style={styles.btnText}>Try again</Text>
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { alignItems: "center", padding: 32 },
  title: {
    marginTop: 12,
    fontFamily: "Poppins_700Bold",
    fontSize: 16,
    color: colors.textPrimary,
  },
  message: {
    marginTop: 6,
    fontFamily: "Poppins_400Regular",
    fontSize: 13,
    color: colors.textSecondary,
    textAlign: "center",
  },
  btn: {
    marginTop: 16,
    backgroundColor: colors.primaryTeal,
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 10,
  },
  btnText: { color: "#fff", fontFamily: "Poppins_600SemiBold" },
});
