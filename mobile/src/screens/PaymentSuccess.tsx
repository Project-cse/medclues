import { StyleSheet, Text, View } from "react-native";
import { router } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { PrimaryButton } from "@/components/ui/PrimaryButton";
import { brand, colors } from "@/constants/theme";

export type PaymentSuccessProps = {
  orderId: string;
  paymentId: string;
  amount: string;
  appointmentId?: string;
};

export function PaymentSuccess({
  orderId,
  paymentId,
  amount,
}: PaymentSuccessProps) {
  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.center}>
        <Ionicons name="checkmark-circle" size={72} color={brand.blue} />
        <Text style={styles.title}>Payment Successful</Text>
        <Text style={styles.sub}>Your appointment payment is confirmed.</Text>
        <View style={styles.card}>
          <Row label="Amount" value={`₹${amount}`} />
          <Row label="Order ID" value={orderId} />
          <Row label="Payment ID" value={paymentId} />
        </View>
        <PrimaryButton
          title="Back to appointments"
          onPress={() => router.replace("/(patient)/appointments")}
        />
      </View>
    </SafeAreaView>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.row}>
      <Text style={styles.rowLabel}>{label}</Text>
      <Text style={styles.rowValue} numberOfLines={1}>
        {value}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  center: { flex: 1, alignItems: "center", justifyContent: "center", padding: 24 },
  title: {
    fontFamily: "Poppins_700Bold",
    fontSize: 22,
    color: colors.textPrimary,
    marginTop: 16,
  },
  sub: {
    fontFamily: "Poppins_400Regular",
    color: colors.textSecondary,
    marginTop: 8,
    textAlign: "center",
  },
  card: {
    width: "100%",
    backgroundColor: colors.white,
    borderRadius: 14,
    padding: 16,
    marginVertical: 24,
    borderWidth: 1,
    borderColor: colors.border,
  },
  row: { marginBottom: 12 },
  rowLabel: { fontFamily: "Poppins_600SemiBold", fontSize: 12, color: colors.textSecondary },
  rowValue: { fontFamily: "Poppins_400Regular", fontSize: 14, color: colors.textPrimary, marginTop: 2 },
});
