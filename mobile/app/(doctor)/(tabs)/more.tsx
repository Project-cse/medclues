import { ScrollView, Pressable, StyleSheet, Text, View } from "react-native";
import { router, type Href } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { PanelShell } from "@/components/panels/PanelShell";
import { DOCTOR_DRAWER } from "@/components/panels/doctorDrawer";
import { useAuth } from "@/hooks/useAuth";
import { panelColors } from "@/constants/panelTheme";

const EXTRA = DOCTOR_DRAWER.filter((d) =>
  ["Schedule", "Prescription", "Medical Records", "Earnings", "Notifications", "Profile", "Settings"].includes(d.label)
);

export default function DoctorMoreScreen() {
  const { user } = useAuth();
  return (
    <PanelShell title="More" drawerHeader={{ name: user?.name ?? "Doctor", subtitle: "Menu" }} drawerItems={DOCTOR_DRAWER}>
      <ScrollView contentContainerStyle={styles.list}>
        {EXTRA.map((item) => (
          <Pressable
            key={item.label}
            style={styles.row}
            onPress={() => item.href && router.push(item.href as Href)}
          >
            <Ionicons name={item.icon} size={22} color={panelColors.primary} />
            <Text style={styles.label}>{item.label}</Text>
            <Ionicons name="chevron-forward" size={20} color={panelColors.textSecondary} />
          </Pressable>
        ))}
      </ScrollView>
    </PanelShell>
  );
}

const styles = StyleSheet.create({
  list: { padding: 16, paddingBottom: 80 },
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
    backgroundColor: panelColors.card,
    padding: 16,
    borderRadius: 12,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: panelColors.border,
  },
  label: { flex: 1, fontFamily: "Poppins_600SemiBold", color: panelColors.textPrimary },
});
