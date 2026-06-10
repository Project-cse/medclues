import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { router, useLocalSearchParams } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { useDoctor } from "@/hooks/useDoctors";
import { StarRating } from "@/components/ui/StarRating";
import { StatusPill } from "@/components/ui/StatusPill";
import { PrimaryButton } from "@/components/ui/PrimaryButton";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { ErrorState } from "@/components/ui/ErrorState";
import { AvatarImage } from "@/components/ui/AvatarImage";
import { formatInr } from "@/utils/format";
import { colors, shadows } from "@/constants/theme";

export default function DoctorDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { data: doctor, isLoading, error, refetch } = useDoctor(id);

  if (isLoading) {
    return (
      <SafeAreaView style={styles.safe}>
        <ListSkeleton rows={2} />
      </SafeAreaView>
    );
  }

  if (error || !doctor) {
    return (
      <SafeAreaView style={styles.safe}>
        <ErrorState
          message={error instanceof Error ? error.message : "Doctor not found"}
          onRetry={() => refetch()}
        />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safe} edges={["top", "bottom"]}>
      <View style={styles.topBar}>
        <Pressable onPress={() => router.back()} hitSlop={12}>
          <Ionicons name="arrow-back" size={24} color={colors.textPrimary} />
        </Pressable>
        <Pressable hitSlop={12}>
          <Ionicons name="heart-outline" size={24} color={colors.red} />
        </Pressable>
      </View>

      <ScrollView contentContainerStyle={styles.scroll}>
        <AvatarImage uri={doctor.profilePicUrl} size={140} />
        <Text style={styles.name}>{doctor.name}</Text>
        <View style={styles.locRow}>
          <Ionicons name="location" size={16} color={colors.primaryTeal} />
          <Text style={styles.spec}>{doctor.specialization}</Text>
        </View>
        {doctor.hospitalName ? (
          <Text style={styles.hospital}>{doctor.hospitalName}</Text>
        ) : null}
        {doctor.experience ? (
          <StatusPill variant="experience" label={`${doctor.experience} Experience`} />
        ) : null}
        <StarRating rating={doctor.rating} reviews={doctor.reviewCount} />
        {doctor.consultationFee != null ? (
          <Text style={styles.fee}>Consultation: {formatInr(doctor.consultationFee)}</Text>
        ) : null}

        <View style={styles.actions}>
          {[
            { icon: "call-outline", label: "Call" },
            { icon: "chatbubble-outline", label: "Message" },
            { icon: "videocam-outline", label: "Video" },
            { icon: "share-social-outline", label: "Share" },
          ].map((a) => (
            <Pressable key={a.label} style={[styles.actionBtn, shadows.card]}>
              <Ionicons name={a.icon as keyof typeof Ionicons.glyphMap} size={22} color={colors.primaryTeal} />
              <Text style={styles.actionLabel}>{a.label}</Text>
            </Pressable>
          ))}
        </View>

        {doctor.about ? (
          <>
            <Text style={styles.section}>About Doctor</Text>
            <Text style={styles.body}>{doctor.about}</Text>
          </>
        ) : null}

        {doctor.qualification || doctor.education ? (
          <>
            <Text style={styles.section}>Education</Text>
            <Text style={styles.body}>
              {[doctor.qualification, doctor.education].filter(Boolean).join(" — ")}
            </Text>
          </>
        ) : null}

        <Text style={styles.section}>Availability</Text>
        <Text style={styles.body}>
          Days: {doctor.availableDays ?? "Mon - Sat"}
        </Text>
        <Text style={styles.body}>
          Time: {doctor.availableTime ?? "10:00 AM - 06:00 PM"}
        </Text>

        <View style={{ height: 100 }} />
      </ScrollView>

      <View style={styles.footer}>
        <PrimaryButton
          title="Book Appointment"
          onPress={() =>
            router.push({
              pathname: "/book-appointment",
              params: { doctorId: String(doctor.id) },
            })
          }
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  topBar: {
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 16,
    paddingVertical: 8,
  },
  scroll: { paddingHorizontal: 16, alignItems: "center" },
  name: {
    fontFamily: "Poppins_700Bold",
    fontSize: 24,
    color: colors.textPrimary,
    marginTop: 16,
    textAlign: "center",
  },
  locRow: { flexDirection: "row", alignItems: "center", gap: 6, marginTop: 8 },
  spec: { fontFamily: "Poppins_400Regular", color: colors.primaryTeal, fontSize: 14 },
  hospital: {
    fontFamily: "Poppins_400Regular",
    color: colors.textSecondary,
    marginTop: 4,
  },
  fee: {
    fontFamily: "Poppins_600SemiBold",
    color: colors.textPrimary,
    marginTop: 8,
  },
  actions: {
    flexDirection: "row",
    gap: 10,
    marginTop: 20,
    alignSelf: "stretch",
  },
  actionBtn: {
    flex: 1,
    backgroundColor: colors.white,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: "center",
    gap: 6,
  },
  actionLabel: { fontFamily: "Poppins_600SemiBold", fontSize: 12, color: colors.textPrimary },
  section: {
    alignSelf: "flex-start",
    fontFamily: "Poppins_700Bold",
    fontSize: 17,
    color: colors.textPrimary,
    marginTop: 24,
    marginBottom: 8,
  },
  body: {
    alignSelf: "flex-start",
    fontFamily: "Poppins_400Regular",
    fontSize: 14,
    color: colors.textSecondary,
    lineHeight: 22,
  },
  footer: { position: "absolute", bottom: 16, left: 0, right: 0 },
});
