import { ScrollView, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { navigateBackToProfile } from "@/utils/profileNavigation";
import { useAppTheme } from "@/hooks/useAppTheme";

export default function PaymentMethodsScreen() {
  const { theme } = useAppTheme();

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: theme.background }]} edges={["top"]}>
      <ScreenHeader title="Payment Methods" onBack={navigateBackToProfile} />
      <ScrollView contentContainerStyle={styles.scroll}>
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <Text style={[styles.text, { color: theme.textSecondary }]}>
            Online consultations use Razorpay at booking time. In-clinic visits can be paid at the
            hospital reception.
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  scroll: { padding: 16 },
  card: { borderRadius: 16, padding: 20, borderWidth: 1 },
  text: { fontFamily: "Poppins_400Regular", fontSize: 14, lineHeight: 22 },
});
