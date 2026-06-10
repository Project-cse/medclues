import { ScrollView, StyleSheet, Text, View, Pressable } from "react-native";
import { router, type Href } from "expo-router";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { useAuth } from "@/hooks/useAuth";
import { logout } from "@/services/staffApi";
import { panelColors } from "@/constants/panelTheme";

export default function AdminProfileScreen() {
  const { user } = useAuth();
  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Profile" />
      <ScrollView contentContainerStyle={{ padding: 16, alignItems: "center" }}>
        <View style={styles.av}><Text style={styles.avt}>A</Text></View>
        <Text style={styles.name}>{user?.name ?? "Admin User"}</Text>
        <Text style={styles.email}>{user?.email ?? "admin@medichain.com"}</Text>
        <Pressable onPress={() => router.push("/(admin)/settings" as Href)}><Text style={styles.link}>App Settings</Text></Pressable>
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
  email: { color: panelColors.textSecondary, marginTop: 8 },
  link: { marginTop: 24, color: panelColors.primary, fontFamily: "Poppins_600SemiBold" },
  logout: { marginTop: 16, color: panelColors.cancelled, fontFamily: "Poppins_700Bold" },
});
