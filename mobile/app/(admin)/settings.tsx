import { ScrollView, StyleSheet, Switch, Text, View } from "react-native";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { panelColors } from "@/constants/panelTheme";
import { useState } from "react";

export default function AdminSettingsScreen() {
  const [email, setEmail] = useState(true);
  const [sms, setSms] = useState(true);
  const [dark, setDark] = useState(false);
  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Settings" />
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        <Text style={styles.section}>GENERAL</Text>
        <Text style={styles.row}>App Name: MediChain+</Text>
        <Text style={styles.row}>Version: 1.0.0</Text>
        <Text style={styles.section}>NOTIFICATIONS</Text>
        <View style={styles.switchRow}><Text>Email</Text><Switch value={email} onValueChange={setEmail} /></View>
        <View style={styles.switchRow}><Text>SMS</Text><Switch value={sms} onValueChange={setSms} /></View>
        <Text style={styles.section}>APPEARANCE</Text>
        <View style={styles.switchRow}><Text>Dark Mode</Text><Switch value={dark} onValueChange={setDark} /></View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  section: { fontFamily: "Poppins_700Bold", fontSize: 12, color: panelColors.textSecondary, marginTop: 16 },
  row: { backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginTop: 8 },
  switchRow: { flexDirection: "row", justifyContent: "space-between", backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginTop: 8 },
});
