import { Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { AvatarImage } from "@/components/ui/AvatarImage";
import { StarRating } from "@/components/ui/StarRating";
import { useColors } from "@/hooks/useColors";
import type { Doctor } from "@/types/domain";

/** Fixed card width — do not shrink in grid layout. */
export const TOP_DOCTOR_CARD_WIDTH = 120;

type Props = {
  doctor: Doctor;
  onPress: () => void;
  width?: number;
};

export function TopDoctorCard({ doctor, onPress, width = TOP_DOCTOR_CARD_WIDTH }: Props) {
  const colors = useColors();
  const displayName = doctor.name.replace(/^Dr\.?\s*/i, "").trim();

  return (
    <Pressable
      style={[
        styles.card,
        colors.shadows.card,
        { width, backgroundColor: colors.white },
      ]}
      onPress={onPress}
    >
      <View style={styles.avatarWrap}>
        <View style={[styles.ringOuter, { borderColor: colors.specCircleFill }]}>
          <View style={[styles.ring, { borderColor: colors.specCircleFill }]}>
            <AvatarImage uri={doctor.profilePicUrl} size={66} />
          </View>
        </View>
        <View style={[styles.badge, { backgroundColor: colors.specCircleFill }]}>
          <Ionicons name="checkmark" size={12} color="#fff" />
        </View>
      </View>
      <Text style={[styles.name, { color: colors.textPrimary }]} numberOfLines={2}>
        {displayName}
      </Text>
      <Text style={[styles.spec, { color: colors.textSecondary }]} numberOfLines={1}>
        {doctor.specialization}
      </Text>
      <View style={styles.ratingRow}>
        <Ionicons name="star" size={12} color="#FBBF24" />
        <Text style={[styles.ratingText, { color: colors.textSecondary }]}>
          {doctor.rating?.toFixed(1) ?? "4.8"}
          {doctor.reviewCount != null ? ` (${doctor.reviewCount})` : ""}
        </Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: 16,
    padding: 12,
    alignItems: "center",
    marginRight: 0,
  },
  avatarWrap: {
    position: "relative",
    marginBottom: 8,
  },
  ringOuter: {
    borderWidth: 2,
    borderRadius: 42,
    padding: 3,
  },
  ring: {
    borderWidth: 2,
    borderRadius: 36,
    padding: 2,
  },
  badge: {
    position: "absolute",
    right: 0,
    bottom: 0,
    width: 22,
    height: 22,
    borderRadius: 11,
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 2,
    borderColor: "#fff",
  },
  name: {
    fontFamily: "Poppins_700Bold",
    fontSize: 13,
    textAlign: "center",
    minHeight: 34,
  },
  spec: {
    fontFamily: "Poppins_400Regular",
    fontSize: 11,
    textAlign: "center",
    marginTop: 2,
  },
  ratingRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    marginTop: 6,
  },
  ratingText: {
    fontFamily: "Poppins_400Regular",
    fontSize: 11,
  },
});
