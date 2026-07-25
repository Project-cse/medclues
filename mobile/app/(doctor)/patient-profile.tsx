import { ScrollView, StyleSheet, Text, View } from "react-native";
import { useLocalSearchParams } from "expo-router";
import { useQuery } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { fetchDoctorPatient } from "@/services/panels/doctorPanel";
import { panelColors } from "@/constants/panelTheme";

export default function DoctorPatientProfileScreen() {
  const { patientId } = useLocalSearchParams<{ patientId: string }>();
  const { data } = useQuery({
    queryKey: ["doctor", "patient", patientId],
    queryFn: () => fetchDoctorPatient(patientId!),
    enabled: !!patientId,
  });

  return (
    <View style={styles.safe}>
      <ScreenHeader title="Patient Profile" />
      <ScrollView contentContainerStyle={{ padding: 16, alignItems: "center" }}>
        <View style={styles.avatar}><Text style={styles.avatarText}>{data?.name?.charAt(0) ?? "P"}</Text></View>
        <Text style={styles.name}>{data?.name ?? "Patient"}</Text>
        <Text style={styles.sub}>{[data?.gender, data?.age].filter(Boolean).join(" · ")}</Text>
        <View style={styles.card}>
          <Text style={styles.k}>Phone</Text><Text style={styles.v}>{data?.phone ?? "—"}</Text>
          <Text style={styles.k}>Email</Text><Text style={styles.v}>{data?.email ?? "—"}</Text>
          <Text style={styles.k}>Blood Group</Text><Text style={styles.v}>{data?.bloodGroup ?? "—"}</Text>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: panelColors.background },
  avatar: { width: 88, height: 88, borderRadius: 44, backgroundColor: panelColors.accent, alignItems: "center", justifyContent: "center" },
  avatarText: { color: "#fff", fontSize: 36, fontFamily: "Poppins_700Bold" },
  name: { fontFamily: "Poppins_700Bold", fontSize: 22, marginTop: 12 },
  sub: { color: panelColors.textSecondary, marginBottom: 16 },
  card: { width: "100%", backgroundColor: panelColors.card, padding: 16, borderRadius: 12, borderWidth: 1, borderColor: panelColors.border },
  k: { fontSize: 12, color: panelColors.textSecondary, marginTop: 10 },
  v: { fontFamily: "Poppins_600SemiBold" },
});
