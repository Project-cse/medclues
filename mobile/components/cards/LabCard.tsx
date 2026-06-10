import { StyleSheet, Text, View } from "react-native";
import { Image } from "expo-image";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { colors, shadows } from "@/constants/theme";
import { StarRating } from "@/components/ui/StarRating";
import { StatusPill } from "@/components/ui/StatusPill";
import { PrimaryButton } from "@/components/ui/PrimaryButton";
import type { Lab } from "@/types/domain";

export function LabCard({ lab }: { lab: Lab }) {
  return (
    <View style={[styles.card, shadows.card]}>
      <View style={styles.row}>
        <View style={styles.thumb}>
          {lab.image ? (
            <Image source={{ uri: lab.image }} style={styles.img} contentFit="cover" />
          ) : (
            <Ionicons name="flask" size={26} color={colors.primaryTeal} />
          )}
        </View>
        <View style={styles.body}>
          <Text style={styles.name}>{lab.name}</Text>
          {lab.address ? (
            <View style={styles.locRow}>
              <Ionicons name="location-outline" size={14} color={colors.textSecondary} />
              <Text style={styles.loc} numberOfLines={1}>
                {lab.address}
              </Text>
            </View>
          ) : null}
          <StarRating rating={lab.rating} reviews={lab.reviewCount} />
          <View style={styles.badges}>
            {lab.isOpen ? <StatusPill variant="open" /> : null}
            {lab.isVerified ? <StatusPill variant="verified" /> : null}
          </View>
          {lab.availableTests.length > 0 ? (
            <View style={styles.tags}>
              {lab.availableTests.map((t) => (
                <View key={t} style={styles.tag}>
                  <Text style={styles.tagText}>{t}</Text>
                </View>
              ))}
            </View>
          ) : null}
        </View>
      </View>
      <PrimaryButton
        title="Book Appointment"
        onPress={() =>
          router.push({ pathname: "/labs/[id]", params: { id: String(lab.id) } })
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.white,
    borderRadius: 16,
    marginHorizontal: 16,
    marginBottom: 14,
    padding: 14,
  },
  row: { flexDirection: "row", gap: 12, marginBottom: 10 },
  thumb: {
    width: 68,
    height: 68,
    borderRadius: 12,
    backgroundColor: "#E0F2FE",
    alignItems: "center",
    justifyContent: "center",
    overflow: "hidden",
  },
  img: { width: 68, height: 68 },
  body: { flex: 1 },
  name: { fontSize: 16, fontWeight: "700", color: colors.textPrimary },
  locRow: { flexDirection: "row", gap: 4, marginTop: 4, alignItems: "center" },
  loc: { flex: 1, fontSize: 12, color: colors.textSecondary },
  badges: { flexDirection: "row", gap: 6, marginTop: 8 },
  tags: { flexDirection: "row", flexWrap: "wrap", gap: 6, marginTop: 8 },
  tag: {
    backgroundColor: "#F1F5F9",
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  tagText: { fontSize: 11, color: colors.textSecondary },
});
