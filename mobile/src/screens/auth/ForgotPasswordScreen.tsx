import { useState } from "react";
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { router, type Href } from "expo-router";
import { AuthFlowShell } from "@/src/components/auth/AuthFlowShell";
import { sendForgotPasswordOtp } from "@/src/api/auth";
import {
  getAuthTheme,
  isValidEmail,
  loginPathForTheme,
  type AuthThemeKey,
} from "@/src/utils/authTheme";
import { colors } from "@/constants/theme";
import { useToast } from "@/providers/ToastProvider";

type Props = {
  theme: AuthThemeKey;
  role: string;
};

export function ForgotPasswordScreen({ theme, role }: Props) {
  const { showToast } = useToast();
  const t = getAuthTheme(theme);
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [inlineEmailError, setInlineEmailError] = useState("");

  const sendOtp = async () => {
    setError("");
    if (!isValidEmail(email)) {
      setInlineEmailError("Enter a valid email address");
      return;
    }
    setInlineEmailError("");
    setLoading(true);
    try {
      const res = await sendForgotPasswordOtp(email, role);
      if (res.dev_otp) {
        showToast(`Dev OTP: ${res.dev_otp}`, "info");
      }
      const href =
        `/(auth)/otp-verify?email=${encodeURIComponent(email.trim())}` +
        `&theme=${theme}&role=${encodeURIComponent(role)}` as Href;
      router.push(href);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to send OTP");
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthFlowShell
      theme={theme}
      title="Forgot Password"
      subtitle="Enter your registered email to receive an OTP"
      icon="mail-outline"
      footer={
        <Pressable
          style={styles.footer}
          onPress={() => router.replace(loginPathForTheme(theme) as Href)}
        >
          <Text style={styles.footerText}>
            Remembered your password?{" "}
            <Text style={[styles.footerLink, { color: t.primary }]}>Sign in</Text>
          </Text>
        </Pressable>
      }
    >
      <Text style={styles.label}>Email Address</Text>
      <TextInput
        style={[styles.input, inlineEmailError ? styles.inputError : null]}
        placeholder="your@email.com"
        placeholderTextColor={colors.textSecondary}
        keyboardType="email-address"
        autoCapitalize="none"
        value={email}
        onChangeText={(v) => {
          setEmail(v);
          setInlineEmailError("");
        }}
      />
      {inlineEmailError ? <Text style={styles.inlineError}>{inlineEmailError}</Text> : null}

      <Pressable
        style={[styles.btn, { backgroundColor: t.primary }, loading && styles.btnDisabled]}
        onPress={sendOtp}
        disabled={loading}
      >
        {loading ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.btnText}>Send OTP</Text>
        )}
      </Pressable>
      {error ? <Text style={styles.error}>{error}</Text> : null}
    </AuthFlowShell>
  );
}

const styles = StyleSheet.create({
  label: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 13,
    color: colors.textPrimary,
    marginBottom: 6,
  },
  input: {
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: "#F8FAFC",
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontFamily: "Poppins_400Regular",
    fontSize: 15,
    marginBottom: 6,
  },
  inputError: { borderColor: "#EF4444" },
  inlineError: {
    color: "#EF4444",
    fontFamily: "Poppins_400Regular",
    fontSize: 12,
    marginBottom: 8,
  },
  btn: {
    borderRadius: 28,
    paddingVertical: 16,
    alignItems: "center",
    marginTop: 12,
  },
  btnDisabled: { opacity: 0.7 },
  btnText: { color: "#fff", fontFamily: "Poppins_700Bold", fontSize: 16 },
  error: {
    color: "#EF4444",
    fontFamily: "Poppins_400Regular",
    fontSize: 13,
    marginTop: 10,
    textAlign: "center",
  },
  footer: { marginTop: 22, alignItems: "center" },
  footerText: { fontFamily: "Poppins_400Regular", color: colors.textSecondary },
  footerLink: { fontFamily: "Poppins_700Bold" },
});
