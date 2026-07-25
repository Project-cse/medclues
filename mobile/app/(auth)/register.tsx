import { useState } from "react";
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { router } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { authService, loginWithRole } from "@/services/auth";
import { PrimaryButton } from "@/components/ui/PrimaryButton";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { useToast } from "@/providers/ToastProvider";
import { colors } from "@/constants/theme";
import { getPostLoginRoute } from "@/utils/authRoutes";

export default function RegisterScreen() {
  const { showToast } = useToast();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [gender, setGender] = useState("Male");
  const [dob, setDob] = useState("");
  const [loading, setLoading] = useState(false);

  const handleRegister = async () => {
    setLoading(true);
    try {
      const { data } = await authService.register({ name, email, phone, password, gender, dob });
      if (!data.success) throw new Error(String(data.message ?? "Registration failed"));
      const result = await loginWithRole({ email, password, role: "patient" });
      showToast("Account created!", "success");
      router.replace(getPostLoginRoute(result.user.role));
    } catch (err) {
      showToast(err instanceof Error ? err.message : "Registration failed", "error");
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.safe}>
      <ScreenHeader title="Create Account" />
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        style={{ flex: 1 }}
      >
        <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
          {[
            { label: "Full Name", value: name, set: setName },
            { label: "Email", value: email, set: setEmail, keyboard: "email-address" as const },
            { label: "Phone", value: phone, set: setPhone, keyboard: "phone-pad" as const },
            { label: "Password", value: password, set: setPassword, secure: true },
            { label: "Date of Birth (DD/MM/YYYY)", value: dob, set: setDob },
          ].map((f) => (
            <View key={f.label}>
              <Text style={styles.label}>{f.label}</Text>
              <TextInput
                style={styles.input}
                value={f.value}
                onChangeText={f.set}
                secureTextEntry={f.secure}
                keyboardType={f.keyboard}
                autoCapitalize="none"
                placeholderTextColor={colors.textSecondary}
              />
            </View>
          ))}

          <Text style={styles.label}>Gender</Text>
          <View style={styles.genderRow}>
            {["Male", "Female", "Other"].map((g) => (
              <Pressable
                key={g}
                onPress={() => setGender(g)}
                style={[styles.genderPill, gender === g && styles.genderActive]}
              >
                <Text style={[styles.genderText, gender === g && styles.genderTextActive]}>
                  {g}
                </Text>
              </Pressable>
            ))}
          </View>

          <View style={{ marginTop: 16 }}>
            <PrimaryButton title="Register" onPress={handleRegister} loading={loading} />
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  scroll: { padding: 16, paddingBottom: 40 },
  label: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 13,
    color: colors.textPrimary,
    marginBottom: 6,
    marginTop: 8,
  },
  input: {
    backgroundColor: colors.white,
    borderRadius: 12,
    padding: 14,
    fontFamily: "Poppins_400Regular",
    borderWidth: 1,
    borderColor: colors.border,
  },
  genderRow: { flexDirection: "row", gap: 8, marginBottom: 8 },
  genderPill: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 999,
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.border,
  },
  genderActive: { backgroundColor: colors.primaryTeal, borderColor: colors.primaryTeal },
  genderText: { fontFamily: "Poppins_400Regular", color: colors.textSecondary },
  genderTextActive: { color: "#fff", fontFamily: "Poppins_600SemiBold" },
});
