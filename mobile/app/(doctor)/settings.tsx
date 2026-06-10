import { ScrollView, StyleSheet, Switch, Text, View } from "react-native";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { panelColors } from "@/constants/panelTheme";
import { useState } from "react";

export default function DoctorSettingsScreen() {
  const [push, setPush] = useState(true);
  const [email, setEmail] = useState(true);
  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Settings" />
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        <Text style={styles.section}>NOTIFICATIONS</Text>
        <View style={styles.row}><Text style={styles.label}>Push Notifications</Text><Switch value={push} onValueChange={setPush} /></View>
        <View style={styles.row}><Text style={styles.label}>Email Notifications</Text><Switch value={email} onValueChange={setEmail} /></View>
        <Text style={styles.section}>ABOUT</Text>
        <Text style={styles.meta}>MediChain+ v1.0.0</Text>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  section: { fontFamily: "Poppins_700Bold", color: panelColors.textSecondary, marginTop: 16, marginBottom: 8, fontSize: 12 },
  row: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 8 },
  label: { fontFamily: "Poppins_600SemiBold" },
  meta: { color: panelColors.textSecondary },
});
