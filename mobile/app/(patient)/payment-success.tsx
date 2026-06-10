import { StyleSheet, Text, View } from "react-native";
import { router, useLocalSearchParams } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { AmbulanciaLottie } from "@/components/lottie/AmbulanciaLottie";
import { PrimaryButton } from "@/components/ui/PrimaryButton";
import { colors } from "@/constants/theme";

export default function PaymentSuccessScreen() {
  const params = useLocalSearchParams<{
    appointmentId?: string;
    amount?: string;
    doctorName?: string;
    specialization?: string;
    date?: string;
    time?: string;
    visitType?: string;
  }>();

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.center}>
        <AmbulanciaLottie width={200} height={200} loop={false} autoPlay />
        <Text style={styles.title}>Payment Successful! 🎉</Text>
        <Text style={styles.sub}>₹{params.amount ?? "0"} paid successfully</Text>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>{params.doctorName}</Text>
          <Text style={styles.cardSub}>{params.specialization}</Text>
          <Text style={styles.row}>📅 {params.date} · {params.time}</Text>
          <Text style={styles.badge}>{params.visitType}</Text>
          {params.appointmentId ? (
            <Text style={styles.id}>ID: {params.appointmentId}</Text>
          ) : null}
        </View>

        <PrimaryButton
          title="View Appointment"
          onPress={() => router.replace("/(patient)/appointments")}
        />
        <View style={{ height: 12 }} />
        <PrimaryButton
          title="Go Home"
          variant="outline"
          onPress={() => router.replace("/(patient)/home")}
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: "#F0FDF4" },
  center: { flex: 1, alignItems: "center", justifyContent: "center", padding: 24 },
  title: {
    fontFamily: "Poppins_700Bold",
    fontSize: 24,
    color: "#16A34A",
    marginTop: 8,
    textAlign: "center",
  },
  sub: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 16,
    color: colors.textSecondary,
    marginTop: 6,
    marginBottom: 20,
  },
  card: {
    width: "100%",
    backgroundColor: "#fff",
    borderRadius: 16,
    padding: 20,
    marginBottom: 24,
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
    marginTop: 12,
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
});
