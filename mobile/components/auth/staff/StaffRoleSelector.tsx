import { Pressable, StyleSheet, Text, View } from "react-native";
import { MaterialCommunityIcons } from "@expo/vector-icons";
import type { UserRole } from "@/types/api";

export type StaffRoleKey = "doctor" | "dean" | "superAdmin";

const RED = "#B91C1C";
const RED_BORDER = "#DC2626";

const ROLES: {
  key: StaffRoleKey;
  apiRole: UserRole;
  label: string;
  icon: keyof typeof MaterialCommunityIcons.glyphMap;
}[] = [
  { key: "doctor", apiRole: "doctor", label: "Doctor", icon: "stethoscope" },
  { key: "dean", apiRole: "dean", label: "Dean", icon: "school" },
  { key: "superAdmin", apiRole: "admin", label: "Super Admin", icon: "shield-plus" },
];

type Props = {
  selected: StaffRoleKey;
  onSelect: (key: StaffRoleKey, apiRole: UserRole) => void;
};

function RoleCard({
  role,
  selected,
  onPress,
}: {
  role: (typeof ROLES)[number];
  selected: boolean;
  onPress: () => void;
}) {
  return (
    <View style={styles.cardOuter}>
      <Pressable
        onPress={onPress}
        style={({ pressed }) => [
          styles.card,
          selected ? styles.cardSelected : styles.cardDefault,
          pressed && styles.cardPressed,
        ]}
      >
        {selected ? (
          <View style={styles.badge}>
            <MaterialCommunityIcons name="check" size={12} color="#fff" />
          </View>
        ) : null}
        <MaterialCommunityIcons
          name={role.icon}
          size={28}
          color={selected ? RED_BORDER : "#9CA3AF"}
        />
        <Text style={[styles.label, selected && styles.labelSelected]} numberOfLines={2}>
          {role.label}
        </Text>
      </Pressable>
    </View>
  );
}

export function StaffRoleSelector({ selected, onSelect }: Props) {
  return (
    <View style={styles.wrap}>
      <Text style={styles.heading}>Choose your role</Text>
      <View style={styles.row}>
        {ROLES.map((r) => (
          <RoleCard
            key={r.key}
            role={r}
            selected={selected === r.key}
            onPress={() => onSelect(r.key, r.apiRole)}
          />
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { marginBottom: 4 },
  heading: {
    fontFamily: "Poppins_700Bold",
    fontSize: 16,
    color: "#111827",
    marginBottom: 12,
  },
  row: {
    flexDirection: "row",
    gap: 10,
  },
  cardOuter: {
    flex: 1,
  },
  card: {
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 14,
    paddingHorizontal: 4,
    borderRadius: 14,
    minHeight: 88,
    position: "relative",
  },
  cardDefault: {
    backgroundColor: "#fff",
    borderWidth: 1,
    borderColor: "#E5E7EB",
  },
  cardSelected: {
    backgroundColor: "#FEF2F2",
    borderWidth: 2,
    borderColor: RED_BORDER,
  },
  cardPressed: {
    opacity: 0.88,
  },
  badge: {
    position: "absolute",
    top: 6,
    right: 6,
    width: 18,
    height: 18,
    borderRadius: 9,
    backgroundColor: RED_BORDER,
    alignItems: "center",
    justifyContent: "center",
  },
  label: {
    marginTop: 8,
    fontFamily: "Poppins_600SemiBold",
    fontSize: 11,
    color: "#374151",
    textAlign: "center",
  },
  labelSelected: {
    fontFamily: "Poppins_700Bold",
    color: RED,
  },
});
