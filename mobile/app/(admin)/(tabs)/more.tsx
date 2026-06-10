import { ScrollView, Pressable, StyleSheet, Text } from "react-native";
import { router, type Href } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { PanelShell } from "@/components/panels/PanelShell";
import { ADMIN_DRAWER } from "@/components/panels/adminDrawer";
import { useAuth } from "@/hooks/useAuth";
import { panelColors } from "@/constants/panelTheme";

const EXTRA = ADMIN_DRAWER.filter((d) => !["Dashboard", "Appointments", "Patients"].includes(d.label));

export default function AdminMoreScreen() {
  const { user } = useAuth();
  return (
    <PanelShell title="More" drawerHeader={{ name: "MediChain+", subtitle: user?.email ?? "" }} drawerItems={ADMIN_DRAWER}>
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        {EXTRA.map((item) => (
          <Pressable key={item.label} style={styles.row} onPress={() => item.href && router.push(item.href as Href)}>
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
  row: { flexDirection: "row", alignItems: "center", gap: 14, backgroundColor: panelColors.card, padding: 16, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  label: { flex: 1, fontFamily: "Poppins_600SemiBold" },
});
