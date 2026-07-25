import { StyleSheet, Text, View } from "react-native";

export type StrengthLevel = "Weak" | "Fair" | "Good" | "Strong";

export function calcPasswordStrength(password: string): {
  level: StrengthLevel;
  score: number;
} {
  let score = 0;
  if (password.length >= 8) score += 1;
  if (/[A-Z]/.test(password)) score += 1;
  if (/[0-9]/.test(password)) score += 1;
  if (/[^A-Za-z0-9]/.test(password)) score += 1;

  const levels: StrengthLevel[] = ["Weak", "Fair", "Good", "Strong"];
  return { level: levels[Math.max(0, score - 1)] ?? "Weak", score };
}

const SEGMENT_COLORS = ["#EF4444", "#F97316", "#3B82F6", "#22C55E"];

export function PasswordStrengthBar({ password }: { password: string }) {
  const { level, score } = calcPasswordStrength(password);

  return (
    <View style={styles.wrap}>
      <View style={styles.barRow}>
        {[0, 1, 2, 3].map((i) => (
          <View
            key={i}
            style={[
              styles.segment,
              {
                backgroundColor: i < score ? SEGMENT_COLORS[i] : "#E2E8F0",
              },
            ]}
          />
        ))}
      </View>
      <Text style={[styles.label, { color: SEGMENT_COLORS[Math.max(0, score - 1)] ?? "#94A3B8" }]}>
        {password ? level : ""}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { flexDirection: "row", alignItems: "center", gap: 10, marginBottom: 12 },
  barRow: { flex: 1, flexDirection: "row", gap: 4 },
  segment: { flex: 1, height: 4, borderRadius: 2 },
  label: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 11,
    minWidth: 48,
    textAlign: "right",
  },
});
