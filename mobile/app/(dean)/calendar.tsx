import { ScrollView, StyleSheet, Text, View } from "react-native";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { panelColors } from "@/constants/panelTheme";

export default function DeanCalendarScreen() {
  const events = [
    { time: "09:00 - 10:00", title: "Faculty Meeting", location: "Admin Block" },
    { time: "14:00 - 15:30", title: "Student Council", location: "Hall A" },
  ];
  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Calendar" />
      <Text style={styles.month}>May 2025</Text>
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        <Text style={styles.h}>Today&apos;s Events</Text>
        {events.map((e, i) => (
          <View key={i} style={styles.card}>
            <Text style={styles.time}>{e.time}</Text>
            <Text style={styles.title}>{e.title}</Text>
            <Text style={styles.loc}>{e.location}</Text>
          </View>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  month: { textAlign: "center", fontFamily: "Poppins_700Bold", fontSize: 18, marginTop: 8 },
  h: { fontFamily: "Poppins_700Bold", marginBottom: 12 },
  card: { backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  time: { color: panelColors.primary, fontFamily: "Poppins_600SemiBold" },
  title: { fontFamily: "Poppins_600SemiBold", marginTop: 4 },
  loc: { fontSize: 12, color: panelColors.textSecondary },
});
