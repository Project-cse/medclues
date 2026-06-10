import { useEffect, useState } from "react";
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { KeyboardSafeScrollView } from "@/components/ui/KeyboardSafeScrollView";
import { navigateBackToProfile } from "@/utils/profileNavigation";
import { useMe } from "@/hooks/useMe";
import { useAppTheme } from "@/hooks/useAppTheme";
import { authService } from "@/services/auth";
import { useAuthStore } from "@/store/authStore";
import { useToast } from "@/providers/ToastProvider";

export default function PersonalInfoScreen() {
  const { theme } = useAppTheme();
  const { showToast } = useToast();
  const queryClient = useQueryClient();
  const updateUser = useAuthStore((s) => s.updateUser);
  const { data: me } = useMe();

  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [gender, setGender] = useState("");
  const [dob, setDob] = useState("");
  const [bloodGroup, setBloodGroup] = useState("");

  useEffect(() => {
    if (!me) return;
    setName(me.name ?? "");
    setPhone(me.phone ?? "");
    setGender(me.gender ?? "");
    setDob(me.dob ?? "");
    setBloodGroup(me.bloodGroup ?? "");
  }, [me]);

  const saveMutation = useMutation({
    mutationFn: () =>
      authService.patchProfile({
        name: name.trim(),
        phone: phone.trim(),
        gender: gender.trim(),
        dob: dob.trim(),
        bloodGroup: bloodGroup.trim(),
      }),
    onSuccess: async (profile) => {
      if (profile) {
        await updateUser({
          name: profile.name,
          phone: profile.phone,
          image: profile.profilePicUrl,
        });
      }
      queryClient.invalidateQueries({ queryKey: ["me"] });
      showToast("Profile updated successfully!", "success");
    },
    onError: (e) => {
      showToast(e instanceof Error ? e.message : "Update failed", "error");
    },
  });

  const field = (label: string, value: string, onChange: (t: string) => void) => (
    <View style={styles.field}>
      <Text style={[styles.label, { color: theme.textSecondary }]}>{label}</Text>
      <TextInput
        style={[
          styles.input,
          {
            backgroundColor: theme.surface,
            borderColor: theme.border,
            color: theme.text,
          },
        ]}
        value={value}
        onChangeText={onChange}
        placeholderTextColor={theme.textSecondary}
      />
    </View>
  );

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: theme.background }]} edges={["top"]}>
      <ScreenHeader title="Personal Information" onBack={navigateBackToProfile} />
      <KeyboardSafeScrollView contentContainerStyle={styles.scroll}>
        {field("Full Name", name, setName)}
        {field("Phone", phone, setPhone)}
        {field("Gender", gender, setGender)}
        {field("Date of Birth (YYYY-MM-DD)", dob, setDob)}
        {field("Blood Group", bloodGroup, setBloodGroup)}

        <Pressable
          style={[styles.btn, { backgroundColor: theme.primary }]}
          onPress={() => saveMutation.mutate()}
          disabled={saveMutation.isPending}
        >
          {saveMutation.isPending ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.btnText}>Save Changes</Text>
          )}
        </Pressable>
      </KeyboardSafeScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  scroll: { padding: 16, paddingBottom: 32 },
  field: { marginBottom: 16 },
  label: { fontFamily: "Poppins_600SemiBold", fontSize: 13, marginBottom: 6 },
  input: {
    borderWidth: 1,
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontFamily: "Poppins_400Regular",
    fontSize: 15,
  },
  btn: {
    marginTop: 8,
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: "center",
  },
  btnText: {
    fontFamily: "Poppins_700Bold",
    fontSize: 16,
    color: "#fff",
  },
});
