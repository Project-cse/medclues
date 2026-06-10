import { Pressable, StyleSheet, Text, View } from "react-native";
import { router } from "expo-router";
import { colors, shadows } from "@/constants/theme";
import { StarRating } from "@/components/ui/StarRating";
import { StatusPill } from "@/components/ui/StatusPill";
import { AvatarImage } from "@/components/ui/AvatarImage";
import type { Doctor } from "@/types/domain";

const BORDER_COLORS = ["#0EA5E9", "#2563EB", "#10B981", "#F97316", "#8B5CF6"];

export function DoctorListCard({ doctor, index = 0 }: { doctor: Doctor; index?: number }) {
  const borderColor = BORDER_COLORS[index % BORDER_COLORS.length];
  const expLabel = doctor.experience ?? undefined;

  return (
    <Pressable
      onPress={() =>
        router.push({ pathname: "/doctors/[id]", params: { id: String(doctor.id) } })
      }
      style={[styles.card, shadows.card, { borderLeftColor: borderColor }]}
    >
      <AvatarImage uri={doctor.profilePicUrl} size={56} borderColor={borderColor} />
      <View style={styles.center}>
        <Text style={styles.name}>{doctor.name}</Text>
        <Text style={styles.spec}>{doctor.specialization}</Text>
        {expLabel ? <StatusPill variant="experience" label={expLabel} /> : null}
      </View>
      <View style={styles.right}>
        <StarRating rating={doctor.rating} showCount={false} size={12} />
        {doctor.rating != null ? (
          <Text style={styles.ratingNum}>{doctor.rating.toFixed(1)}</Text>
        ) : null}
        {doctor.available ? <StatusPill variant="available" /> : null}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: colors.white,
    borderRadius: 16,
    marginHorizontal: 16,
    marginBottom: 12,
    padding: 14,
    borderLeftWidth: 4,
    gap: 12,
  },
  center: { flex: 1, gap: 4 },
  name: { fontSize: 15, fontWeight: "700", color: colors.textPrimary },
  spec: { fontSize: 12, color: colors.textSecondary },
  right: { alignItems: "flex-end", gap: 6 },
  ratingNum: { fontSize: 12, fontWeight: "700", color: colors.textPrimary },
});
