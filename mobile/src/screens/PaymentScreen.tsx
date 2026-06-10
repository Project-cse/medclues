import { useState } from "react";
import { ActivityIndicator, StyleSheet, Text, View } from "react-native";
import { router, type Href } from "expo-router";
import * as WebBrowser from "expo-web-browser";
import { SafeAreaView } from "react-native-safe-area-context";
import { PrimaryButton } from "@/components/ui/PrimaryButton";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { useToast } from "@/providers/ToastProvider";
import { API_URL } from "@/constants/config";
import { parsePaymentRedirectUrl } from "@/hooks/usePayment";
import { createOrder, verifyPayment } from "@/src/api/payments";
import { brand, colors } from "@/constants/theme";

export type PaymentScreenProps = {
  amount: number;
  patientName: string;
  email: string;
  contact: string;
  appointmentId?: string;
};

export function PaymentScreen({
  amount,
  patientName,
  email,
  contact,
  appointmentId,
}: PaymentScreenProps) {
  const { showToast } = useToast();
  const [paying, setPaying] = useState(false);

  const payNow = async () => {
    setPaying(true);
    try {
      const order = await createOrder(amount);
      if (!order.checkout_token) {
        throw new Error("Payment checkout could not be started");
      }

      const checkoutUrl = `${API_URL}/api/payments/checkout?token=${encodeURIComponent(order.checkout_token)}`;
      const result = await WebBrowser.openAuthSessionAsync(checkoutUrl, "medichain://payment");

      if (result.type !== "success" || !result.url) {
        showToast("Payment cancelled", "error");
        return;
      }

      const redirect = parsePaymentRedirectUrl(result.url);
      if (!redirect || redirect.cancelled) {
        showToast("Payment cancelled", "error");
        return;
      }
      if (redirect.failed) {
        showToast("Payment failed. Try again.", "error");
        return;
      }

      await verifyPayment({
        razorpay_order_id: redirect.razorpay_order_id,
        razorpay_payment_id: redirect.razorpay_payment_id,
        razorpay_signature: redirect.razorpay_signature,
      });

      const successHref =
        `/payment-success?orderId=${encodeURIComponent(redirect.razorpay_order_id)}` +
        `&paymentId=${encodeURIComponent(redirect.razorpay_payment_id)}` +
        `&amount=${encodeURIComponent(String(amount))}` +
        `&appointmentId=${encodeURIComponent(appointmentId ?? "")}` as Href;
      router.replace(successHref);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Payment failed";
      showToast(msg, "error");
    } finally {
      setPaying(false);
    }
  };

  return (
    <SafeAreaView style={styles.safe}>
      <ScreenHeader title="Payment" />
      <View style={styles.card}>
        <Text style={styles.label}>Amount due</Text>
        <Text style={styles.amount}>₹{amount.toFixed(2)}</Text>
        <Text style={styles.meta}>Patient: {patientName}</Text>
        <Text style={styles.meta}>{email}</Text>
        <Text style={styles.meta}>{contact}</Text>
      </View>

      {paying ? (
        <View style={styles.loading}>
          <ActivityIndicator size="large" color={brand.blue} />
          <Text style={styles.loadingText}>Opening secure checkout…</Text>
        </View>
      ) : (
        <View style={styles.btn}>
          <PrimaryButton title="Pay Now" onPress={payNow} />
        </View>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  card: {
    margin: 16,
    backgroundColor: colors.white,
    borderRadius: 16,
    padding: 20,
    borderWidth: 1,
    borderColor: colors.border,
  },
  label: {
    fontFamily: "Poppins_600SemiBold",
    color: colors.textSecondary,
    fontSize: 13,
  },
  amount: {
    fontFamily: "Poppins_700Bold",
    fontSize: 36,
    color: brand.blue,
    marginVertical: 8,
  },
  meta: {
    fontFamily: "Poppins_400Regular",
    color: colors.textSecondary,
    fontSize: 14,
    marginTop: 4,
  },
  loading: { alignItems: "center", marginTop: 24, gap: 12 },
  loadingText: { fontFamily: "Poppins_400Regular", color: colors.textSecondary },
  btn: { paddingHorizontal: 16, marginTop: 8 },
});
