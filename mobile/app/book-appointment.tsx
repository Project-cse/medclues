import { useMemo, useState } from "react";
import {
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { router, useLocalSearchParams } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { useDoctor } from "@/hooks/useDoctors";
import { useAvailableSlots, useBookAppointment } from "@/hooks/usePatientAppointments";
import { useRazorpayPayment } from "@/hooks/usePayment";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { StarRating } from "@/components/ui/StarRating";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { ErrorState } from "@/components/ui/ErrorState";
import { LoadingAmbulancia } from "@/components/ui/LoadingAmbulancia";
import { AvatarImage } from "@/components/ui/AvatarImage";
import { useToast } from "@/providers/ToastProvider";
import { buildNext7Days } from "@/utils/format";
import { colors } from "@/constants/theme";

function navigateToSuccess(params: Record<string, string>) {
  router.replace({
    pathname: "/(patient)/booking-success",
    params,
  });
}

export default function BookAppointmentScreen() {
  const { doctorId } = useLocalSearchParams<{ doctorId: string }>();
  const { showToast } = useToast();
  const week = useMemo(() => buildNext7Days(), []);
  const [dayIndex, setDayIndex] = useState(0);
  const selectedDate = week[dayIndex].slotDate;
  const [selectedSlot, setSelectedSlot] = useState<string | null>(null);
  const [visitType, setVisitType] = useState<"in" | "online">("in");
  const [note, setNote] = useState("");

  const { data: doctor, isLoading: docLoading, error: docError, refetch } = useDoctor(doctorId);
  const { data: daySlots, isLoading: slotsLoading } = useAvailableSlots(doctorId, selectedDate);
  const { initiatePayment, isLoading: paying } = useRazorpayPayment();
  const bookMutation = useBookAppointment();

  const slots = daySlots?.slots ?? [];
  const fee = doctor?.consultationFee ?? 500;
  const loading = paying || bookMutation.isPending;

  const baseSuccessParams = () => ({
    doctorName: doctor?.name ?? "",
    specialization: doctor?.specialization ?? "",
    hospitalName: doctor?.hospitalName ?? "",
    date: selectedDate,
    time: selectedSlot ?? "",
    amount: String(fee),
    visitType: visitType === "online" ? "Online" : "In-clinic",
  });

  const handleInClinicBooking = async () => {
    if (!doctorId || !selectedSlot) {
      showToast("Please select date and time", "error");
      return;
    }

    try {
      const data = await bookMutation.mutateAsync({
        doctor_id: doctorId,
        date: selectedDate,
        time: selectedSlot,
        visit_type: "in-clinic",
        notes: note,
        hospitalName: doctor?.hospitalName,
        location: doctor?.address,
      });

      const appointmentId = String(
        (data as Record<string, unknown>).appointmentId ??
          (data as Record<string, unknown>).appointment_id ??
          (data as Record<string, unknown>).id ??
          ""
      );

      navigateToSuccess({
        ...baseSuccessParams(),
        appointmentId,
        paymentType: "in-clinic",
      });
    } catch (e) {
      showToast(e instanceof Error ? e.message : "Booking failed. Try again.", "error");
    }
  };

  const handleOnlineBooking = async () => {
    if (!doctorId || !selectedSlot) {
      showToast("Please select date and time", "error");
      return;
    }

    await initiatePayment({
      doctorId: String(doctorId),
      doctorName: doctor?.name ?? "Doctor",
      consultationFee: fee,
      appointmentDate: selectedDate,
      appointmentTime: selectedSlot,
      notes: note,
      onSuccess: (appointmentId, amountInr, paymentIds) => {
        navigateToSuccess({
          ...baseSuccessParams(),
          appointmentId,
          amount: String(amountInr),
          paymentType: "online",
          visitType: "Online",
          razorpayPaymentId: paymentIds?.razorpay_payment_id ?? "",
          razorpayOrderId: paymentIds?.razorpay_order_id ?? "",
        });
      },
      onFailure: (error) => {
        if (error.toLowerCase().includes("cancel")) {
          showToast("Payment cancelled", "info");
        } else if (error.toLowerCase().includes("internet") || error.toLowerCase().includes("network")) {
          showToast("Failed to connect. Check internet", "error");
        } else {
          showToast(error, "error");
        }
      },
    });
  };

  const handleBooking = () => {
    if (visitType === "in") {
      handleInClinicBooking();
    } else {
      handleOnlineBooking();
    }
  };

  if (docLoading) {
    return (
      <SafeAreaView style={styles.safe}>
        <ScreenHeader title="Book Appointment" />
        <ListSkeleton rows={2} />
      </SafeAreaView>
    );
  }

  if (docError || !doctor) {
    return (
      <SafeAreaView style={styles.safe}>
        <ScreenHeader title="Book Appointment" />
        <ErrorState
          message={docError instanceof Error ? docError.message : "Doctor not found"}
          onRetry={() => refetch()}
        />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={[styles.safe, { position: "relative" }]} edges={["top", "bottom"]}>
      <ScreenHeader title="Book Appointment" />
      <LoadingAmbulancia
        visible={loading}
        message={visitType === "online" ? "Opening secure payment…" : "Booking your appointment…"}
      />

      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : undefined}
        style={{ flex: 1 }}
      >
        <ScrollView contentContainerStyle={styles.scroll}>
          <View style={styles.docCard}>
            <AvatarImage uri={doctor.profilePicUrl} size={56} />
            <View style={styles.docInfo}>
              <Text style={styles.docName}>{doctor.name}</Text>
              <Text style={styles.docSpec}>{doctor.specialization}</Text>
              {doctor.experience ? (
                <Text style={styles.docExp}>{doctor.experience}</Text>
              ) : null}
              <StarRating rating={doctor.rating} showCount={false} size={12} />
            </View>
          </View>

          <Text style={styles.section}>Select Date</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            {week.map((d, i) => (
              <Pressable
                key={d.slotDate}
                onPress={() => {
                  setDayIndex(i);
                  setSelectedSlot(null);
                }}
                style={[styles.dateItem, dayIndex === i && styles.dateItemActive]}
              >
                <Text style={[styles.dateLabel, dayIndex === i && styles.dateLabelActive]}>
                  {d.label}
                </Text>
                <Text style={[styles.dateNum, dayIndex === i && styles.dateNumActive]}>
                  {d.dayNum}
                </Text>
              </Pressable>
            ))}
          </ScrollView>

          <Text style={styles.section}>Select Time</Text>
          {slotsLoading ? (
            <ListSkeleton rows={1} />
          ) : slots.length === 0 ? (
            <Text style={styles.noSlots}>No slots available for this date.</Text>
          ) : (
            <View style={styles.timeGrid}>
              {slots.map((slot) => (
                <Pressable
                  key={slot.time}
                  disabled={!slot.available}
                  onPress={() => setSelectedSlot(slot.time)}
                  style={[
                    styles.timeSlot,
                    !slot.available && styles.timeSlotDisabled,
                    selectedSlot === slot.time && styles.timeSlotActive,
                  ]}
                >
                  <Text
                    style={[
                      styles.timeText,
                      !slot.available && styles.timeTextDisabled,
                      selectedSlot === slot.time && styles.timeTextActive,
                    ]}
                  >
                    {slot.displayTime}
                  </Text>
                </Pressable>
              ))}
            </View>
          )}

          <Text style={styles.section}>Visit Type</Text>
          <View style={styles.visitRow}>
            <Pressable
              style={[styles.visitPill, visitType === "in" && styles.visitActive]}
              onPress={() => setVisitType("in")}
            >
              <Text style={[styles.visitText, visitType === "in" && styles.visitTextActive]}>
                In-clinic
              </Text>
            </Pressable>
            <Pressable
              style={[styles.visitPill, visitType === "online" && styles.visitActive]}
              onPress={() => setVisitType("online")}
            >
              <Text style={[styles.visitText, visitType === "online" && styles.visitTextActive]}>
                Online
              </Text>
            </Pressable>
          </View>

          {visitType === "online" ? (
            <Text style={styles.hint}>Online consultations require advance payment via Razorpay.</Text>
          ) : (
            <Text style={styles.hint}>In-clinic visits: pay at the hospital reception.</Text>
          )}

          <Text style={styles.section}>Add Note (Optional)</Text>
          <TextInput
            style={styles.noteInput}
            placeholder="Write your symptoms..."
            placeholderTextColor={colors.textSecondary}
            multiline
            value={note}
            onChangeText={setNote}
          />
        </ScrollView>
      </KeyboardAvoidingView>

      <View style={styles.footer}>
        <Pressable
          style={[styles.payBtn, (!selectedSlot || loading) && styles.payBtnDisabled]}
          onPress={handleBooking}
          disabled={!selectedSlot || loading}
        >
          {loading ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.payBtnText}>
              {visitType === "in" ? "Book Appointment" : `Pay ₹${fee} & Book`}
            </Text>
          )}
        </Pressable>
        {visitType === "online" ? (
          <Text style={styles.secure}>🔒 Secured by Razorpay</Text>
        ) : null}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  scroll: { padding: 16, paddingBottom: 120 },
  docCard: {
    flexDirection: "row",
    backgroundColor: colors.white,
    borderRadius: 16,
    padding: 14,
    gap: 12,
    marginBottom: 20,
  },
  docInfo: { flex: 1 },
  docName: { fontFamily: "Poppins_700Bold", fontSize: 16, color: colors.textPrimary },
  docSpec: { fontFamily: "Poppins_400Regular", fontSize: 13, color: colors.textSecondary },
  docExp: { fontFamily: "Poppins_400Regular", fontSize: 12, color: colors.orange, marginTop: 2 },
  section: {
    fontFamily: "Poppins_700Bold",
    fontSize: 16,
    color: colors.textPrimary,
    marginBottom: 12,
    marginTop: 8,
  },
  hint: {
    fontFamily: "Poppins_400Regular",
    fontSize: 12,
    color: colors.textSecondary,
    marginBottom: 8,
    marginTop: -4,
  },
  dateItem: {
    alignItems: "center",
    paddingHorizontal: 14,
    paddingVertical: 10,
    marginRight: 10,
    borderRadius: 14,
    backgroundColor: colors.white,
    minWidth: 56,
  },
  dateItemActive: { backgroundColor: colors.primaryTeal },
  dateLabel: { fontSize: 11, fontFamily: "Poppins_400Regular", color: colors.textSecondary },
  dateLabelActive: { color: "#fff" },
  dateNum: {
    fontSize: 20,
    fontFamily: "Poppins_700Bold",
    color: colors.textPrimary,
    marginTop: 4,
  },
  dateNumActive: { color: "#fff" },
  timeGrid: { flexDirection: "row", flexWrap: "wrap", gap: 10, marginBottom: 20 },
  timeSlot: {
    width: "30%",
    paddingVertical: 12,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.white,
    alignItems: "center",
  },
  timeSlotActive: { backgroundColor: colors.primaryTeal, borderColor: colors.primaryTeal },
  timeSlotDisabled: { backgroundColor: "#F1F5F9", borderColor: "#E2E8F0" },
  timeText: { fontFamily: "Poppins_600SemiBold", fontSize: 12, color: colors.textPrimary },
  timeTextActive: { color: "#fff" },
  timeTextDisabled: { color: colors.textSecondary },
  noSlots: {
    fontFamily: "Poppins_400Regular",
    color: colors.textSecondary,
    marginBottom: 16,
  },
  visitRow: { flexDirection: "row", gap: 10, marginBottom: 8 },
  visitPill: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 999,
    backgroundColor: colors.white,
    alignItems: "center",
    borderWidth: 1,
    borderColor: colors.border,
  },
  visitActive: { backgroundColor: colors.primaryTeal, borderColor: colors.primaryTeal },
  visitText: { fontFamily: "Poppins_600SemiBold", color: colors.textSecondary },
  visitTextActive: { color: "#fff" },
  noteInput: {
    backgroundColor: colors.white,
    borderRadius: 12,
    padding: 14,
    minHeight: 100,
    textAlignVertical: "top",
    fontFamily: "Poppins_400Regular",
    borderWidth: 1,
    borderColor: colors.border,
  },
  footer: {
    paddingHorizontal: 16,
    paddingBottom: 16,
    paddingTop: 8,
    backgroundColor: colors.background,
  },
  payBtn: {
    backgroundColor: "#1E3A8A",
    borderRadius: 16,
    paddingVertical: 16,
    alignItems: "center",
    justifyContent: "center",
    minHeight: 56,
  },
  payBtnDisabled: { opacity: 0.55 },
  payBtnText: {
    fontFamily: "Poppins_700Bold",
    fontSize: 17,
    color: "#FFFFFF",
  },
  secure: {
    textAlign: "center",
    marginTop: 10,
    fontFamily: "Poppins_400Regular",
    fontSize: 12,
    color: colors.textSecondary,
  },
});
