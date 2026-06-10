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
import { useToast } from "@/providers/ToastProvider";

function addressToText(addr: unknown): string {
  if (!addr) return "";
  if (typeof addr === "string") return addr;
  if (typeof addr === "object" && addr !== null) {
    const a = addr as { line1?: string; line2?: string };
    return [a.line1, a.line2].filter(Boolean).join(", ");
  }
  return "";
}

export default function AddressScreen() {
  const { theme } = useAppTheme();
  const { showToast } = useToast();
  const queryClient = useQueryClient();
  const { data: me } = useMe();
  const [line1, setLine1] = useState("");
  const [line2, setLine2] = useState("");

  useEffect(() => {
    const text = addressToText(me?.address);
    const parts = text.split(",").map((p) => p.trim());
    setLine1(parts[0] ?? "");
    setLine2(parts.slice(1).join(", "));
  }, [me]);

  const saveMutation = useMutation({
    mutationFn: () =>
      authService.patchProfile({
        address: { line1: line1.trim(), line2: line2.trim() },
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["me"] });
      showToast("Address saved", "success");
    },
    onError: (e) => {
      showToast(e instanceof Error ? e.message : "Update failed", "error");
    },
  });

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: theme.background }]} edges={["top"]}>
      <ScreenHeader title="Address" onBack={navigateBackToProfile} />
      <KeyboardSafeScrollView contentContainerStyle={styles.scroll}>
        <Text style={[styles.label, { color: theme.textSecondary }]}>Address line 1</Text>
        <TextInput
          style={[
            styles.input,
            { backgroundColor: theme.surface, borderColor: theme.border, color: theme.text },
          ]}
          value={line1}
          onChangeText={setLine1}
          placeholder="Street, area"
          placeholderTextColor={theme.textSecondary}
        />
        <Text style={[styles.label, { color: theme.textSecondary, marginTop: 16 }]}>
          Address line 2
        </Text>
        <TextInput
          style={[
            styles.input,
            { backgroundColor: theme.surface, borderColor: theme.border, color: theme.text },
          ]}
          value={line2}
          onChangeText={setLine2}
          placeholder="City, state, PIN"
          placeholderTextColor={theme.textSecondary}
        />
        <Pressable
          style={[styles.btn, { backgroundColor: theme.primary }]}
          onPress={() => saveMutation.mutate()}
          disabled={saveMutation.isPending}
        >
          {saveMutation.isPending ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.btnText}>Save Address</Text>
          )}
        </Pressable>
      </KeyboardSafeScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  scroll: { padding: 16 },
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
    marginTop: 24,
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: "center",
  },
  btnText: { fontFamily: "Poppins_700Bold", fontSize: 16, color: "#fff" },
});
