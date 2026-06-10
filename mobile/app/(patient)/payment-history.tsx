import { useQuery } from "@tanstack/react-query";
import { FlatList, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { navigateBackToProfile } from "@/utils/profileNavigation";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { paymentService, type PaymentHistoryItem } from "@/services/payment";
import { colors } from "@/constants/theme";

function statusColor(status: string) {
  if (status === "paid") return "#16A34A";
  if (status === "failed") return "#DC2626";
  if (status === "refunded") return "#EA580C";
  return colors.textSecondary;
}

function PaymentRow({ item }: { item: PaymentHistoryItem }) {
  return (
    <View style={styles.card}>
      <View style={styles.rowTop}>
        <Text style={styles.doctor}>{item.doctor_name ?? "Consultation"}</Text>
        <Text style={[styles.badge, { color: statusColor(item.status) }]}>
          {item.status?.toUpperCase()}
        </Text>
      </View>
      <Text style={styles.amount}>₹{item.amount_inr ?? (item.amount_paise ?? 0) / 100}</Text>
      {item.payment_id ? (
        <Text style={styles.meta}>Payment: {item.payment_id}</Text>
      ) : null}
      {item.created_at ? (
        <Text style={styles.meta}>{new Date(item.created_at).toLocaleString()}</Text>
      ) : null}
    </View>
  );
}

export default function PaymentHistoryScreen() {
  const { data = [], isLoading } = useQuery({
    queryKey: ["payments", "history"],
    queryFn: () => paymentService.getPaymentHistory(),
  });

  return (
    <SafeAreaView style={styles.safe} edges={["top"]}>
      <ScreenHeader title="Payment History" onBack={navigateBackToProfile} />
      {isLoading ? (
        <ListSkeleton rows={4} />
      ) : (
        <FlatList
          data={data}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => <PaymentRow item={item} />}
          contentContainerStyle={styles.list}
          ListEmptyComponent={
            <Text style={styles.empty}>No payments yet.</Text>
          }
        />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  list: { padding: 16, paddingBottom: 32 },
  card: {
    backgroundColor: colors.white,
    borderRadius: 14,
    padding: 16,
    marginBottom: 12,
  },
  rowTop: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  doctor: { fontFamily: "Poppins_700Bold", fontSize: 15, color: colors.textPrimary },
  badge: { fontFamily: "Poppins_700Bold", fontSize: 12 },
  amount: {
    fontFamily: "Poppins_700Bold",
    fontSize: 18,
    color: colors.textPrimary,
    marginTop: 8,
  },
  meta: {
    fontFamily: "Poppins_400Regular",
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 4,
  },
  empty: {
    textAlign: "center",
    marginTop: 40,
    fontFamily: "Poppins_400Regular",
    color: colors.textSecondary,
  },
});
