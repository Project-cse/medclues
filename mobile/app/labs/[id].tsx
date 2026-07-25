import { Linking, ScrollView, StyleSheet, Text, View } from "react-native";
import { useLocalSearchParams } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { Image } from "expo-image";
import { Ionicons } from "@expo/vector-icons";
import { useLab } from "@/hooks/useLabs";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { StarRating } from "@/components/ui/StarRating";
import { StatusPill } from "@/components/ui/StatusPill";
import { PrimaryButton } from "@/components/ui/PrimaryButton";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { ErrorState } from "@/components/ui/ErrorState";
import { colors, shadows } from "@/constants/theme";

export default function LabDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { data: lab, isLoading, error, refetch } = useLab(id);

  if (isLoading) {
    return (
      <SafeAreaView style={styles.safe}>
        <ScreenHeader title="Lab" />
        <ListSkeleton rows={2} />
      </SafeAreaView>
    );
  }

  if (error || !lab) {
    return (
      <SafeAreaView style={styles.safe}>
        <ScreenHeader title="Lab" />
        <ErrorState
          message={error instanceof Error ? error.message : "Lab not found"}
          onRetry={() => refetch()}
        />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safe} edges={["top", "bottom"]}>
      <ScreenHeader title="" />
      <ScrollView>
        <View style={styles.banner}>
          {lab.image ? (
            <Image source={{ uri: lab.image }} style={styles.bannerImg} contentFit="cover" />
          ) : (
            <Ionicons name="flask" size={48} color={colors.primaryTeal} />
          )}
        </View>
        <View style={styles.content}>
          <Text style={styles.name}>{lab.name}</Text>
          {lab.address ? (
            <View style={styles.loc}>
              <Ionicons name="location-outline" size={16} color={colors.textSecondary} />
              <Text style={styles.locText}>{lab.address}</Text>
            </View>
          ) : null}
          <StarRating rating={lab.rating} reviews={lab.reviewCount} />
          <View style={styles.badges}>
            {lab.isOpen ? <StatusPill variant="open" /> : null}
            {lab.isVerified ? <StatusPill variant="verified" /> : null}
          </View>

          {lab.availableTests.length > 0 ? (
            <>
              <Text style={styles.section}>Available Tests</Text>
              {lab.availableTests.map((t) => (
                <View key={t} style={[styles.testRow, shadows.card]}>
                  <Text style={styles.testName}>{t}</Text>
                </View>
              ))}
            </>
          ) : null}
        </View>
        <View style={{ height: 90 }} />
      </ScrollView>
      <View style={styles.footer}>
        <PrimaryButton
          title="Book Appointment"
          onPress={() => {
            if (lab.address) Linking.openURL(`https://maps.google.com/?q=${encodeURIComponent(lab.address)}`);
          }}
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  banner: {
    height: 160,
    backgroundColor: "#E0F2FE",
    alignItems: "center",
    justifyContent: "center",
  },
  bannerImg: { width: "100%", height: 160 },
  content: { padding: 16 },
  name: { fontFamily: "Poppins_700Bold", fontSize: 22, color: colors.textPrimary },
  loc: { flexDirection: "row", gap: 6, marginTop: 8, alignItems: "center" },
  locText: { fontFamily: "Poppins_400Regular", color: colors.textSecondary, flex: 1 },
  badges: { flexDirection: "row", gap: 8, marginTop: 12 },
  section: {
    fontFamily: "Poppins_700Bold",
    fontSize: 17,
    color: colors.textPrimary,
    marginTop: 24,
    marginBottom: 12,
  },
  testRow: {
    backgroundColor: colors.white,
    padding: 14,
    borderRadius: 12,
    marginBottom: 10,
  },
  testName: { fontFamily: "Poppins_600SemiBold", color: colors.textPrimary },
  footer: { position: "absolute", bottom: 16, left: 0, right: 0 },
});
