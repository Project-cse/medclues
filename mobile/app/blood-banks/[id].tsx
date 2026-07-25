import { Linking, ScrollView, StyleSheet, Text, View } from "react-native";
import { useLocalSearchParams } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { useBloodBank } from "@/hooks/useBloodBanks";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { StarRating } from "@/components/ui/StarRating";
import { StatusPill } from "@/components/ui/StatusPill";
import { PrimaryButton } from "@/components/ui/PrimaryButton";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { ErrorState } from "@/components/ui/ErrorState";
import { colors } from "@/constants/theme";

export default function BloodBankDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { data: bank, isLoading, error, refetch } = useBloodBank(id);

  if (isLoading) {
    return (
      <SafeAreaView style={styles.safe}>
        <ScreenHeader title="Blood Bank" />
        <ListSkeleton rows={2} />
      </SafeAreaView>
    );
  }

  if (error || !bank) {
    return (
      <SafeAreaView style={styles.safe}>
        <ScreenHeader title="Blood Bank" />
        <ErrorState
          message={error instanceof Error ? error.message : "Blood bank not found"}
          onRetry={() => refetch()}
        />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safe} edges={["top", "bottom"]}>
      <ScreenHeader title="" />
      <ScrollView contentContainerStyle={styles.scroll}>
        <View style={styles.iconHero}>
          <Ionicons name="water" size={64} color={colors.red} />
        </View>
        <Text style={styles.name}>{bank.name}</Text>
        {bank.address ? <Text style={styles.loc}>{bank.address}</Text> : null}
        <StarRating rating={bank.rating} reviews={bank.reviewCount} />
        <View style={styles.badges}>
          {bank.isOpen !== false ? <StatusPill variant="open" /> : null}
          {bank.isVerified ? <StatusPill variant="verified" /> : null}
        </View>

        {bank.availableBloodGroups.length > 0 ? (
          <>
            <Text style={styles.section}>Available Blood Groups</Text>
            <View style={styles.grid}>
              {bank.availableBloodGroups.map((g) => (
                <View key={g} style={styles.groupPill}>
                  <Text style={styles.groupText}>{g}</Text>
                </View>
              ))}
            </View>
          </>
        ) : null}

        {bank.about ? (
          <>
            <Text style={styles.section}>About</Text>
            <Text style={styles.about}>{bank.about}</Text>
          </>
        ) : null}

        <Text style={styles.section}>Contact</Text>
        {bank.phone ? (
          <View style={styles.contactRow}>
            <Ionicons name="call-outline" size={18} color={colors.textSecondary} />
            <Text style={styles.contactText}>{bank.phone}</Text>
          </View>
        ) : null}
        {bank.address ? (
          <View style={styles.contactRow}>
            <Ionicons name="location-outline" size={18} color={colors.textSecondary} />
            <Text style={styles.contactText}>{bank.address}</Text>
          </View>
        ) : null}

        <View style={{ height: 100 }} />
      </ScrollView>
      <View style={styles.footer}>
        <PrimaryButton
          title="Call Now"
          variant="red"
          onPress={() => {
            if (bank.phone) Linking.openURL(`tel:${bank.phone.replace(/\s/g, "")}`);
          }}
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  scroll: { padding: 16, alignItems: "center" },
  iconHero: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: "#FEE2E2",
    alignItems: "center",
    justifyContent: "center",
  },
  name: {
    fontFamily: "Poppins_700Bold",
    fontSize: 22,
    color: colors.textPrimary,
    marginTop: 16,
    textAlign: "center",
  },
  loc: { fontFamily: "Poppins_400Regular", color: colors.textSecondary, marginTop: 4 },
  badges: { flexDirection: "row", gap: 8, marginTop: 12 },
  section: {
    alignSelf: "flex-start",
    fontFamily: "Poppins_700Bold",
    fontSize: 17,
    marginTop: 24,
    marginBottom: 12,
    color: colors.textPrimary,
  },
  grid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 10,
    alignSelf: "stretch",
  },
  groupPill: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 10,
    backgroundColor: "#FEE2E2",
    minWidth: "22%",
    alignItems: "center",
  },
  groupText: { fontFamily: "Poppins_700Bold", color: colors.red, fontSize: 15 },
  about: {
    alignSelf: "flex-start",
    fontFamily: "Poppins_400Regular",
    fontSize: 14,
    color: colors.textSecondary,
    lineHeight: 22,
  },
  contactRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    alignSelf: "flex-start",
    marginBottom: 8,
  },
  contactText: { fontFamily: "Poppins_400Regular", color: colors.textSecondary },
  footer: { position: "absolute", bottom: 16, left: 0, right: 0 },
});
