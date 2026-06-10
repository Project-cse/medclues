import { Linking, Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { router } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { AmbulanciaLottie } from "@/components/lottie/AmbulanciaLottie";
import { HospitalCard } from "@/components/cards/HospitalCard";
import { useHospitals } from "@/hooks/useHospitals";
import { useToast } from "@/providers/ToastProvider";
import { colors, shadows } from "@/constants/theme";

const EMERGENCY_NUMBERS = [
  { label: "Emergency", number: "112", filled: true },
  { label: "Ambulance", number: "108", filled: false },
];

export function EmergencyScreenContent() {
  const { showToast } = useToast();
  const { data: hospitals = [], isLoading } = useHospitals();
  const nearby = hospitals.slice(0, 6);

  const handleEmergencyCall = (number: string, name: string) => {
    showToast(`Calling ${number} — ${name}`, "error");
    setTimeout(() => {
      Linking.openURL(`tel:${number}`).catch(() => {
        showToast("Could not open phone dialer", "error");
      });
    }, 400);
  };

  return (
    <SafeAreaView style={styles.safe} edges={["top", "bottom"]}>
      <View style={styles.header}>
        <Pressable onPress={() => router.back()} hitSlop={12} style={styles.backBtn}>
          <Ionicons name="arrow-back" size={24} color={colors.textPrimary} />
        </Pressable>
        <Text style={styles.headerTitle}>Emergency Services</Text>
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scroll}
        keyboardShouldPersistTaps="handled"
      >
        <View style={styles.hero}>
          <AmbulanciaLottie width={280} height={280} loop autoPlay />
          <Text style={styles.title}>Emergency Services</Text>
          <Text style={styles.subtitle}>Help is on the way</Text>
        </View>

        <View style={styles.callSection}>
          {EMERGENCY_NUMBERS.map((item) => (
            <Pressable
              key={item.number}
              style={[
                item.filled ? styles.callCardPrimary : styles.callCardSecondary,
                shadows.card,
              ]}
              onPress={() => handleEmergencyCall(item.number, item.label)}
            >
              <View style={styles.callRow}>
                <Ionicons
                  name="call"
                  size={24}
                  color={item.filled ? "#fff" : colors.red}
                />
                <View style={styles.callText}>
                  <Text
                    style={[
                      styles.callLabel,
                      item.filled && styles.callLabelOnPrimary,
                    ]}
                  >
                    {item.label}
                  </Text>
                  <Text
                    style={[
                      styles.callNumber,
                      item.filled && styles.callNumberOnPrimary,
                    ]}
                  >
                    {item.number}
                  </Text>
                </View>
              </View>
              <Ionicons
                name="chevron-forward"
                size={20}
                color={item.filled ? "#fff" : colors.textSecondary}
              />
            </Pressable>
          ))}
        </View>

        <Text style={styles.sectionTitle}>Nearby Hospitals</Text>
        {isLoading ? (
          <View style={styles.hospitalsLoading}>
            <AmbulanciaLottie width={120} height={120} loop autoPlay />
            <Text style={styles.loadingHospitals}>Loading hospitals…</Text>
          </View>
        ) : nearby.length === 0 ? (
          <Text style={styles.empty}>No hospitals loaded. Check your connection.</Text>
        ) : (
          nearby.map((h) => <HospitalCard key={String(h.id)} hospital={h} />)
        )}

        <Pressable style={styles.moreHospitals} onPress={() => router.push("/hospitals")}>
          <Text style={styles.moreHospitalsText}>View all hospitals</Text>
          <Ionicons name="arrow-forward" size={18} color={colors.red} />
        </Pressable>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: "#FFF5F5" },
  header: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  backBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
    ...shadows.card,
  },
  headerTitle: {
    marginLeft: 12,
    fontFamily: "Poppins_700Bold",
    fontSize: 20,
    color: colors.textPrimary,
  },
  scroll: {
    paddingBottom: 32,
    paddingHorizontal: 16,
  },
  hero: {
    alignItems: "center",
    paddingVertical: 12,
    marginBottom: 8,
    overflow: "visible",
    zIndex: 999,
    elevation: 999,
  },
  title: {
    fontFamily: "Poppins_700Bold",
    fontSize: 22,
    color: "#EF4444",
    marginTop: 8,
    textAlign: "center",
  },
  subtitle: {
    fontFamily: "Poppins_400Regular",
    fontSize: 15,
    color: "#64748B",
    marginTop: 4,
    textAlign: "center",
  },
  callSection: { gap: 12, marginBottom: 8 },
  callCardPrimary: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    backgroundColor: "#EF4444",
    borderRadius: 16,
    padding: 20,
  },
  callCardSecondary: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    backgroundColor: "#fff",
    borderRadius: 16,
    padding: 20,
    borderWidth: 1,
    borderColor: "#FECACA",
  },
  callRow: { flexDirection: "row", alignItems: "center", flex: 1 },
  callText: { marginLeft: 12 },
  callLabel: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 16,
    color: colors.textPrimary,
  },
  callLabelOnPrimary: { color: "#fff" },
  callNumber: {
    fontFamily: "Poppins_700Bold",
    fontSize: 22,
    color: colors.red,
    marginTop: 2,
  },
  callNumberOnPrimary: { color: "#fff" },
  sectionTitle: {
    fontFamily: "Poppins_700Bold",
    fontSize: 18,
    color: colors.textPrimary,
    marginTop: 16,
    marginBottom: 12,
  },
  hospitalsLoading: {
    alignItems: "center",
    paddingVertical: 24,
  },
  loadingHospitals: {
    marginTop: 8,
    fontFamily: "Poppins_400Regular",
    color: colors.textSecondary,
  },
  empty: {
    fontFamily: "Poppins_400Regular",
    fontSize: 14,
    color: colors.textSecondary,
    textAlign: "center",
    paddingVertical: 16,
  },
  moreHospitals: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
    marginTop: 12,
    paddingVertical: 12,
  },
  moreHospitalsText: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 15,
    color: colors.red,
  },
});
