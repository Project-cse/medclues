import { ScrollView, StyleSheet, Text, View, Pressable } from "react-native";
import { router } from "expo-router";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { useAuth } from "@/hooks/useAuth";
import { logout } from "@/services/staffApi";
import { panelColors } from "@/constants/panelTheme";

export default function DeanProfileScreen() {
  const { user } = useAuth();
  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Profile" />
      <ScrollView contentContainerStyle={{ padding: 16, alignItems: "center" }}>
        <View style={styles.av}><Text style={styles.avt}>{user?.name?.charAt(0) ?? "D"}</Text></View>
        <Text style={styles.name}>{user?.name ?? "Dean"}</Text>
        <Text style={styles.role}>Dean</Text>
        <Text style={styles.email}>{user?.email}</Text>
        <Pressable onPress={async () => { await logout(); router.replace("/"); }}>
          <Text style={styles.logout}>Logout</Text>
        </Pressable>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  av: { width: 80, height: 80, borderRadius: 40, backgroundColor: panelColors.primary, alignItems: "center", justifyContent: "center" },
  avt: { color: "#fff", fontSize: 32, fontFamily: "Poppins_700Bold" },
  name: { fontFamily: "Poppins_700Bold", fontSize: 20, marginTop: 12 },
  role: { color: panelColors.textSecondary },
  email: { marginTop: 8, color: panelColors.textSecondary },
  logout: { marginTop: 32, color: panelColors.cancelled, fontFamily: "Poppins_700Bold", fontSize: 16 },
});
