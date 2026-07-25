import { Pressable, StyleSheet, Text, View } from "react-native";
import { Image } from "expo-image";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { colors, shadows, spacing } from "@/constants/theme";
import { StarRating } from "@/components/ui/StarRating";
import { StatusPill } from "@/components/ui/StatusPill";
import { PrimaryButton } from "@/components/ui/PrimaryButton";
import type { Hospital } from "@/types/domain";

export function HospitalCard({ hospital }: { hospital: Hospital }) {
  return (
    <View style={[styles.card, shadows.card]}>
      <View style={styles.row}>
        <View style={styles.thumb}>
          {hospital.image ? (
            <Image source={{ uri: hospital.image }} style={styles.img} contentFit="cover" />
          ) : (
            <Ionicons name="business" size={28} color={colors.textSecondary} />
          )}
        </View>
        <View style={styles.body}>
          <Text style={styles.name}>{hospital.name}</Text>
          {hospital.address ? (
            <View style={styles.locRow}>
              <Ionicons name="location-outline" size={14} color={colors.textSecondary} />
              <Text style={styles.loc} numberOfLines={1}>
                {hospital.address}
              </Text>
            </View>
          ) : null}
          <StarRating rating={hospital.rating} reviews={hospital.reviewCount} />
          <View style={styles.badges}>
            {hospital.isOpen !== false ? <StatusPill variant="open" /> : null}
            {hospital.isVerified ? <StatusPill variant="verified" /> : null}
          </View>
          {hospital.services.length > 0 ? (
            <View style={styles.tags}>
              {hospital.services.map((t) => (
                <View key={t} style={styles.tag}>
                  <Text style={styles.tagText}>{t}</Text>
                </View>
              ))}
            </View>
          ) : null}
        </View>
      </View>
      <PrimaryButton title="Book Appointment" onPress={() => router.push("/doctors")} />
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.white,
    borderRadius: spacing.cardRadius,
    marginHorizontal: spacing.screenX,
    marginBottom: 14,
    padding: 14,
  },
  row: { flexDirection: "row", gap: 12, marginBottom: 12 },
  thumb: {
    width: 72,
    height: 72,
    borderRadius: 12,
    backgroundColor: "#F1F5F9",
    alignItems: "center",
    justifyContent: "center",
    overflow: "hidden",
  },
  img: { width: 72, height: 72 },
  body: { flex: 1 },
  name: { fontSize: 16, fontWeight: "700", color: colors.textPrimary },
  locRow: { flexDirection: "row", alignItems: "center", gap: 4, marginTop: 4 },
  loc: { flex: 1, fontSize: 12, color: colors.textSecondary },
  badges: { flexDirection: "row", gap: 6, marginTop: 8 },
  tags: { flexDirection: "row", flexWrap: "wrap", gap: 6, marginTop: 8 },
  tag: {
    backgroundColor: "#F1F5F9",
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  tagText: { fontSize: 11, color: colors.textSecondary, fontWeight: "500" },
});
