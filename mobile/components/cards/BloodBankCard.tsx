import { Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { colors, shadows } from "@/constants/theme";
import { StarRating } from "@/components/ui/StarRating";
import { StatusPill } from "@/components/ui/StatusPill";
import type { BloodBank } from "@/types/domain";

export function BloodBankCard({ bank }: { bank: BloodBank }) {
  return (
    <Pressable
      style={[styles.card, shadows.card]}
      onPress={() =>
        router.push({ pathname: "/blood-banks/[id]", params: { id: String(bank.id) } })
      }
    >
      <View style={styles.iconBox}>
        <Ionicons name="water" size={28} color={colors.red} />
      </View>
      <View style={styles.body}>
        <Text style={styles.name}>{bank.name}</Text>
        {bank.address ? <Text style={styles.loc}>{bank.address}</Text> : null}
        <StarRating rating={bank.rating} reviews={bank.reviewCount} />
        <View style={styles.badges}>
          {bank.isOpen !== false ? <StatusPill variant="open" /> : null}
          {bank.isVerified ? <StatusPill variant="verified" /> : null}
        </View>
        {bank.availableBloodGroups.length > 0 ? (
          <View style={styles.tags}>
            {bank.availableBloodGroups.map((g) => (
              <View key={g} style={styles.tag}>
                <Text style={styles.tagText}>{g}</Text>
              </View>
            ))}
          </View>
        ) : null}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: "row",
    backgroundColor: colors.white,
    borderRadius: 16,
    marginHorizontal: 16,
    marginBottom: 12,
    padding: 14,
    gap: 12,
  },
  iconBox: {
    width: 56,
    height: 56,
    borderRadius: 14,
    backgroundColor: "#FEE2E2",
    alignItems: "center",
    justifyContent: "center",
  },
  body: { flex: 1 },
  name: { fontSize: 16, fontWeight: "700", color: colors.textPrimary },
  loc: { fontSize: 12, color: colors.textSecondary, marginTop: 2 },
  badges: { flexDirection: "row", gap: 6, marginTop: 8 },
  tags: { flexDirection: "row", flexWrap: "wrap", gap: 6, marginTop: 8 },
  tag: {
    backgroundColor: "#FEE2E2",
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  tagText: { fontSize: 11, fontWeight: "600", color: colors.red },
});
