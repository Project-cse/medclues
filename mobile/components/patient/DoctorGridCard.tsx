import { Image, StyleSheet, Text, View } from "react-native";
import type { DoctorCard } from "@/types/patient";

interface DoctorGridCardProps {
  doctor: DoctorCard;
}

function initials(name: string) {
  return name
    .replace(/^Dr\.?\s*/i, "")
    .split(" ")
    .map((p) => p[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();
}

export function DoctorGridCard({ doctor }: DoctorGridCardProps) {
  const hasImage = Boolean(doctor.image?.startsWith("http"));

  return (
    <View style={styles.card}>
      {hasImage ? (
        <Image source={{ uri: doctor.image }} style={styles.avatar} />
      ) : (
        <View style={[styles.avatar, styles.avatarPlaceholder]}>
          <Text style={styles.initials}>{initials(doctor.name)}</Text>
        </View>
      )}
      <Text style={styles.name} numberOfLines={2}>
        {doctor.name}
      </Text>
      <View style={styles.tagBlue}>
        <Text style={styles.tagBlueText} numberOfLines={1}>
          {doctor.speciality}
        </Text>
      </View>
      <View style={styles.tagGold}>
        <Text style={styles.tagGoldText}>
          {doctor.experience?.includes("Yr") ? doctor.experience : `${doctor.experience ?? "5"} Yrs`}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    width: "48%",
    backgroundColor: "#fff",
    borderRadius: 16,
    padding: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: "#f1f5f9",
    shadowColor: "#0f172a",
    shadowOpacity: 0.05,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },
  avatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
    marginBottom: 8,
    alignSelf: "center",
  },
  avatarPlaceholder: {
    backgroundColor: "#dbeafe",
    alignItems: "center",
    justifyContent: "center",
  },
  initials: {
    fontSize: 18,
    fontWeight: "700",
    color: "#2563EB",
  },
  name: {
    fontSize: 13,
    fontWeight: "700",
    color: "#0f172a",
    minHeight: 36,
  },
  tagBlue: {
    alignSelf: "flex-start",
    backgroundColor: "#eff6ff",
    borderRadius: 8,
    paddingHorizontal: 8,
    paddingVertical: 4,
    marginTop: 6,
    maxWidth: "100%",
  },
  tagBlueText: {
    fontSize: 10,
    fontWeight: "600",
    color: "#2563EB",
  },
  tagGold: {
    alignSelf: "flex-start",
    backgroundColor: "#fef9c3",
    borderRadius: 8,
    paddingHorizontal: 8,
    paddingVertical: 4,
    marginTop: 4,
  },
  tagGoldText: {
    fontSize: 10,
    fontWeight: "600",
    color: "#a16207",
  },
});
