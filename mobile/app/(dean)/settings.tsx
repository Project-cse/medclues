import { ScrollView, StyleSheet, Switch, Text, View } from "react-native";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { panelColors } from "@/constants/panelTheme";
import { useState } from "react";

export default function DeanSettingsScreen() {
  const [push, setPush] = useState(true);
  const [email, setEmail] = useState(true);
  const [sms, setSms] = useState(false);
  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Settings" />
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        <Text style={styles.section}>NOTIFICATIONS</Text>
        <View style={styles.row}><Text>Push</Text><Switch value={push} onValueChange={setPush} /></View>
        <View style={styles.row}><Text>Email</Text><Switch value={email} onValueChange={setEmail} /></View>
        <View style={styles.row}><Text>SMS</Text><Switch value={sms} onValueChange={setSms} /></View>
        <Text style={styles.meta}>App Version 1.0.0</Text>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  section: { fontFamily: "Poppins_700Bold", fontSize: 12, color: panelColors.textSecondary, marginTop: 12 },
  row: { flexDirection: "row", justifyContent: "space-between", backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginTop: 8 },
  meta: { marginTop: 24, color: panelColors.textSecondary },
});
