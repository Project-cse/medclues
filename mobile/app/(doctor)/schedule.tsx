import { ScrollView, StyleSheet, Text, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { fetchDoctorSchedule } from "@/services/panels/doctorPanel";
import { AppointmentStatusBadge, appointmentStatusFromRaw } from "@/components/panels/AppointmentStatusBadge";
import { panelColors } from "@/constants/panelTheme";

export default function DoctorScheduleScreen() {
  const { data } = useQuery({ queryKey: ["doctor", "schedule"], queryFn: fetchDoctorSchedule });

  return (
    <View style={styles.safe}>
      <ScreenHeader title="My Schedule" />
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 40 }}>
        <Text style={styles.date}>Today — {data?.date ?? ""}</Text>
        {(data?.slots ?? []).map((slot) => (
          <View key={String(slot.id)} style={styles.slot}>
            <Text style={styles.time}>{slot.slotTime ?? "—"}</Text>
            <View style={{ flex: 1 }}>
              <Text style={styles.name}>{slot.patientName ?? "Patient"}</Text>
              <Text style={styles.sub}>{slot.status}</Text>
            </View>
            <AppointmentStatusBadge status={appointmentStatusFromRaw(false, slot.status)} />
          </View>
        ))}
        {!data?.slots?.length ? <Text style={styles.empty}>No slots booked today</Text> : null}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: panelColors.background },
  date: { fontFamily: "Poppins_600SemiBold", marginBottom: 12, color: panelColors.textPrimary },
  slot: { flexDirection: "row", gap: 12, backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border },
  time: { fontFamily: "Poppins_700Bold", color: panelColors.primary, width: 56 },
  name: { fontFamily: "Poppins_600SemiBold" },
  sub: { fontSize: 12, color: panelColors.textSecondary },
  empty: { textAlign: "center", color: panelColors.textSecondary, marginTop: 24 },
});
