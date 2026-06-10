import { useMemo, useState } from "react";
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { router, useLocalSearchParams } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { useMe } from "@/hooks/useMe";
import { useToast } from "@/providers/ToastProvider";
import {
  generateReceipt,
  shareReceipt,
  type ReceiptAppointment,
} from "@/utils/generateReceipt";
import { colors } from "@/constants/theme";

export default function BookingSuccessScreen() {
  const params = useLocalSearchParams<{
    appointmentId?: string;
    paymentType?: string;
    doctorName?: string;
    specialization?: string;
    hospitalName?: string;
    date?: string;
    time?: string;
    amount?: string;
    visitType?: string;
    razorpayPaymentId?: string;
    razorpayOrderId?: string;
  }>();
  const { data: me } = useMe();
  const { showToast } = useToast();
  const [downloading, setDownloading] = useState(false);

  const receiptData: ReceiptAppointment = useMemo(
    () => ({
      id: params.appointmentId,
      patient_name: me?.name,
      patient_id: String(me?.id ?? ""),
      patient_phone: me?.phone,
      patient_email: me?.email,
      doctor_name: params.doctorName,
      specialization: params.specialization,
      hospital_name: params.hospitalName ?? "MediChain+ Network",
      appointment_date: params.date,
      appointment_time: params.time,
      visit_type: params.visitType ?? params.paymentType,
      amount: Number(params.amount) || undefined,
      consultation_fee: Number(params.amount) || undefined,
      razorpay_payment_id: params.razorpayPaymentId,
      razorpay_order_id: params.razorpayOrderId,
    }),
    [me, params]
  );

  const isOnline = (params.paymentType ?? "").includes("online");

  const handleDownload = async () => {
    setDownloading(true);
    try {
      const uri = await generateReceipt(receiptData);
      await shareReceipt(uri);
      showToast("Receipt ready to save or share", "success");
    } catch (e) {
      showToast(e instanceof Error ? e.message : "Could not generate receipt", "error");
    } finally {
      setDownloading(false);
    }
  };

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.center}>
        <View style={styles.checkCircle}>
          <Ionicons name="checkmark" size={56} color="#fff" />
        </View>
        <Text style={styles.title}>Booking Confirmed! 🎉</Text>
        <Text style={styles.sub}>
          {isOnline ? `₹${params.amount ?? "0"} paid successfully` : "Pay at clinic on visit"}
        </Text>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>{params.doctorName}</Text>
          <Text style={styles.cardSub}>{params.specialization}</Text>
          {params.hospitalName ? (
            <Text style={styles.row}>🏥 {params.hospitalName}</Text>
          ) : null}
          <Text style={styles.row}>
            📅 {params.date} · {params.time}
          </Text>
          <Text style={styles.badge}>{params.visitType ?? params.paymentType}</Text>
          {params.appointmentId ? (
            <Text style={styles.id}>Appointment ID: {params.appointmentId}</Text>
          ) : null}
        </View>

        <Pressable
          style={[styles.outlineBtn, downloading && styles.btnDisabled]}
          onPress={handleDownload}
          disabled={downloading}
        >
          {downloading ? (
            <ActivityIndicator color={colors.primaryTeal} />
          ) : (
            <Text style={styles.outlineText}>📥 Download Receipt</Text>
          )}
        </Pressable>

        <Pressable style={styles.filledBtn} onPress={() => router.replace("/(patient)/home")}>
          <Text style={styles.filledText}>🏠 Go to Home</Text>
        </Pressable>

        <Pressable
          style={styles.linkBtn}
          onPress={() => router.replace("/(patient)/appointments")}
        >
          <Text style={styles.linkText}>View Appointments</Text>
        </Pressable>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: "#F0FDF4" },
  center: { flex: 1, alignItems: "center", justifyContent: "center", padding: 24 },
  checkCircle: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: "#16A34A",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 16,
  },
  title: {
    fontFamily: "Poppins_700Bold",
    fontSize: 24,
    color: "#16A34A",
    textAlign: "center",
  },
  sub: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 15,
    color: colors.textSecondary,
    marginTop: 6,
    marginBottom: 20,
  },
  card: {
    width: "100%",
    backgroundColor: "#fff",
    borderRadius: 16,
    padding: 20,
    marginBottom: 20,
  },
  cardTitle: { fontFamily: "Poppins_700Bold", fontSize: 18, color: colors.textPrimary },
  cardSub: {
    fontFamily: "Poppins_400Regular",
    fontSize: 14,
    color: colors.textSecondary,
    marginTop: 4,
  },
  row: {
    fontFamily: "Poppins_400Regular",
    fontSize: 14,
    color: colors.textPrimary,
    marginTop: 10,
  },
  badge: {
    alignSelf: "flex-start",
    marginTop: 10,
    backgroundColor: "#DBEAFE",
    color: "#1D4ED8",
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 999,
    fontFamily: "Poppins_600SemiBold",
    fontSize: 12,
    overflow: "hidden",
  },
  id: {
    marginTop: 12,
    fontFamily: "Poppins_400Regular",
    fontSize: 12,
    color: colors.textSecondary,
  },
  outlineBtn: {
    width: "100%",
    borderWidth: 2,
    borderColor: colors.primaryTeal,
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: "center",
    marginBottom: 12,
    backgroundColor: "#fff",
  },
  outlineText: {
    fontFamily: "Poppins_700Bold",
    fontSize: 16,
    color: colors.primaryTeal,
  },
  filledBtn: {
    width: "100%",
    backgroundColor: "#1E3A8A",
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: "center",
  },
  filledText: {
    fontFamily: "Poppins_700Bold",
    fontSize: 16,
    color: "#fff",
  },
  linkBtn: { marginTop: 16, padding: 8 },
  linkText: {
    fontFamily: "Poppins_600SemiBold",
    color: colors.primaryTeal,
    fontSize: 14,
  },
  btnDisabled: { opacity: 0.6 },
});
