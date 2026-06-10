import { useState } from "react";
import { ScrollView, StyleSheet, Text, TextInput, View, Pressable } from "react-native";
import { router } from "expo-router";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { PrimaryButton } from "@/components/ui/PrimaryButton";
import { savePrescription } from "@/services/panels/doctorPanel";
import { useToast } from "@/providers/ToastProvider";
import { panelColors } from "@/constants/panelTheme";

type Med = { name: string; dosage: string; instructions: string; duration: string };

export default function DoctorNewPrescriptionScreen() {
  const { showToast } = useToast();
  const [diagnosis, setDiagnosis] = useState("");
  const [notes, setNotes] = useState("");
  const [meds, setMeds] = useState<Med[]>([{ name: "", dosage: "", instructions: "", duration: "" }]);
  const [loading, setLoading] = useState(false);

  const save = async () => {
    setLoading(true);
    try {
      await savePrescription({
        patientId: 0,
        diagnosis,
        medicines: meds.filter((m) => m.name.trim()),
        notes,
      });
      showToast("Prescription saved", "success");
      router.back();
    } catch (e) {
      showToast(e instanceof Error ? e.message : "Failed", "error");
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.safe}>
      <ScreenHeader title="New Prescription" />
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 40 }}>
        <Text style={styles.label}>Diagnosis</Text>
        <TextInput style={styles.input} value={diagnosis} onChangeText={setDiagnosis} placeholder="Enter diagnosis" />
        {meds.map((m, i) => (
          <View key={i} style={styles.medBlock}>
            <TextInput style={styles.input} placeholder="Medicine" value={m.name} onChangeText={(t) => { const n = [...meds]; n[i].name = t; setMeds(n); }} />
            <TextInput style={styles.input} placeholder="Dosage (1-0-1)" value={m.dosage} onChangeText={(t) => { const n = [...meds]; n[i].dosage = t; setMeds(n); }} />
            <TextInput style={styles.input} placeholder="Instructions" value={m.instructions} onChangeText={(t) => { const n = [...meds]; n[i].instructions = t; setMeds(n); }} />
            <TextInput style={styles.input} placeholder="Duration" value={m.duration} onChangeText={(t) => { const n = [...meds]; n[i].duration = t; setMeds(n); }} />
          </View>
        ))}
        <Pressable onPress={() => setMeds([...meds, { name: "", dosage: "", instructions: "", duration: "" }])}>
          <Text style={styles.add}>+ Add Medicine</Text>
        </Pressable>
        <Text style={styles.label}>Notes (optional)</Text>
        <TextInput style={[styles.input, { minHeight: 80 }]} multiline value={notes} onChangeText={setNotes} />
        <PrimaryButton title="Save Prescription" onPress={save} loading={loading} variant="ubuntu" fullWidth />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: panelColors.background },
  label: { fontFamily: "Poppins_600SemiBold", marginBottom: 6, color: panelColors.textPrimary },
  input: { backgroundColor: panelColors.card, borderRadius: 12, padding: 12, marginBottom: 10, borderWidth: 1, borderColor: panelColors.border, fontFamily: "Poppins_400Regular" },
  medBlock: { marginBottom: 12, padding: 12, backgroundColor: "#f0f4f8", borderRadius: 12 },
  add: { color: panelColors.primary, fontFamily: "Poppins_600SemiBold", marginBottom: 16 },
});
