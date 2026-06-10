import { ScrollView, StyleSheet, Text, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { LinearGradient } from "expo-linear-gradient";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { fetchDoctorEarnings } from "@/services/panels/doctorPanel";
import { panelColors } from "@/constants/panelTheme";

export default function DoctorEarningsScreen() {
  const { data } = useQuery({ queryKey: ["doctor", "earnings"], queryFn: fetchDoctorEarnings });
  return (
    <View style={styles.safe}>
      <ScreenHeader title="Earnings" />
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        <LinearGradient colors={[panelColors.primary, "#0D47A1"]} style={styles.total}>
          <Text style={styles.totalLabel}>Total Earnings</Text>
          <Text style={styles.totalVal}>₹{data?.total ?? 0}</Text>
        </LinearGradient>
        <Text style={styles.h}>Recent Transactions</Text>
        {(data?.transactions ?? []).map((t) => (
          <View key={String(t.id)} style={styles.row}>
            <View style={{ flex: 1 }}>
              <Text style={styles.desc}>{t.description}</Text>
              <Text style={styles.date}>{t.date}</Text>
            </View>
            <Text style={styles.amt}>+₹{t.amount}</Text>
          </View>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: panelColors.background },
  total: { borderRadius: 16, padding: 24, marginBottom: 20 },
  totalLabel: { color: "rgba(255,255,255,0.9)", fontFamily: "Poppins_400Regular" },
  totalVal: { color: "#fff", fontFamily: "Poppins_700Bold", fontSize: 32, marginTop: 8 },
  h: { fontFamily: "Poppins_700Bold", marginBottom: 12, color: panelColors.textPrimary },
  row: { flexDirection: "row", backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 8, borderWidth: 1, borderColor: panelColors.border },
  desc: { fontFamily: "Poppins_600SemiBold" },
  date: { fontSize: 12, color: panelColors.textSecondary },
  amt: { color: panelColors.completed, fontFamily: "Poppins_700Bold" },
});
