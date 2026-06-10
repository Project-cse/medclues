import { ScrollView } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { ReportListItem } from "@/components/panels/ReportListItem";
import { fetchDoctorMedicalRecords } from "@/services/panels/doctorPanel";
import { panelColors } from "@/constants/panelTheme";
import { View, StyleSheet, Text } from "react-native";

export default function DoctorMedicalRecordsScreen() {
  const { data } = useQuery({ queryKey: ["doctor", "records"], queryFn: fetchDoctorMedicalRecords });
  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Medical Records" />
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        <ReportListItem title="Net Records" subtitle={`${data?.net ?? 0} Records`} icon="folder-outline" />
        <ReportListItem title="Lab Reports" subtitle={`${data?.lab ?? 0} Records`} icon="flask-outline" iconColor={panelColors.accent} />
        <ReportListItem title="Imaging Reports" subtitle={`${data?.imaging ?? 0} Records`} icon="scan-outline" />
        <ReportListItem title="Prescriptions" subtitle={`${data?.prescriptions ?? 0} Records`} icon="medical-outline" />
        <Text style={styles.h}>Recent Records</Text>
        {(data?.recent ?? []).map((r) => (
          <ReportListItem key={String(r.id)} title={r.name} subtitle={String(r.date ?? "")} />
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  h: { fontFamily: "Poppins_700Bold", fontSize: 16, marginVertical: 12, color: panelColors.textPrimary },
});
