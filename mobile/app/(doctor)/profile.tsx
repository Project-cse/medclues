import { ScrollView, StyleSheet, Text, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { fetchDoctorProfile } from "@/services/panels/doctorPanel";
import { panelColors } from "@/constants/panelTheme";

export default function DoctorProfileScreen() {
  const { data } = useQuery({ queryKey: ["doctor", "profile"], queryFn: fetchDoctorProfile });
  const rows: { key: string; value?: string }[] = [
    { key: "Email", value: data?.email != null ? String(data.email) : undefined },
    { key: "Phone", value: data?.phone != null ? String(data.phone) : undefined },
    { key: "Experience", value: data?.experience != null ? String(data.experience) : undefined },
    { key: "Speciality", value: data?.speciality != null ? String(data.speciality) : undefined },
    { key: "Address", value: data?.address != null ? String(data.address) : undefined },
    { key: "Fees", value: data?.fees != null ? `₹${data.fees}` : undefined },
  ];
  return (
    <View style={styles.safe}>
      <ScreenHeader title="Profile" />
      <ScrollView contentContainerStyle={{ padding: 16, alignItems: "center" }}>
        <View style={styles.avatar}><Text style={styles.avatarText}>{String(data?.name ?? "D").charAt(0)}</Text></View>
        <Text style={styles.name}>{String(data?.name ?? "Doctor")}</Text>
        <Text style={styles.sub}>{String(data?.degree ?? data?.speciality ?? "")}</Text>
        {rows.map(({ key, value }) =>
          value ? (
            <View key={key} style={styles.row}>
              <Text style={styles.k}>{key}</Text>
              <Text style={styles.v}>{value}</Text>
            </View>
          ) : null
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: panelColors.background },
  avatar: { width: 80, height: 80, borderRadius: 40, backgroundColor: panelColors.primary, alignItems: "center", justifyContent: "center" },
  avatarText: { color: "#fff", fontSize: 32, fontFamily: "Poppins_700Bold" },
  name: { fontFamily: "Poppins_700Bold", fontSize: 20, marginTop: 12 },
  sub: { color: panelColors.textSecondary, marginBottom: 20 },
  row: { width: "100%", backgroundColor: panelColors.card, padding: 14, borderRadius: 12, marginBottom: 8, borderWidth: 1, borderColor: panelColors.border },
  k: { fontSize: 12, color: panelColors.textSecondary },
  v: { fontFamily: "Poppins_600SemiBold", marginTop: 4 },
});
