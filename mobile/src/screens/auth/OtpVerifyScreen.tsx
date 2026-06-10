import { useCallback, useEffect, useRef, useState } from "react";
import {
  ActivityIndicator,
  Animated,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { router, type Href } from "expo-router";
import { AuthFlowShell } from "@/src/components/auth/AuthFlowShell";
import { OtpInput } from "@/src/components/auth/OtpInput";
import { sendForgotPasswordOtp, verifyOtp } from "@/src/api/auth";
import {
  getAuthTheme,
  loginPathForTheme,
  maskEmail,
  type AuthThemeKey,
} from "@/src/utils/authTheme";
import { colors } from "@/constants/theme";

type Props = {
  email: string;
  theme: AuthThemeKey;
  role: string;
};

function runShake(anim: Animated.Value) {
  Animated.sequence([
    Animated.timing(anim, { toValue: 8, duration: 50, useNativeDriver: true }),
    Animated.timing(anim, { toValue: -8, duration: 50, useNativeDriver: true }),
    Animated.timing(anim, { toValue: 8, duration: 50, useNativeDriver: true }),
    Animated.timing(anim, { toValue: -8, duration: 50, useNativeDriver: true }),
    Animated.timing(anim, { toValue: 0, duration: 50, useNativeDriver: true }),
  ]).start();
}

export function OtpVerifyScreen({ email, theme, role }: Props) {
  const t = getAuthTheme(theme);
  const shakeAnim = useRef(new Animated.Value(0)).current;
  const [otp, setOtp] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [seconds, setSeconds] = useState(60);
  const [resendCount, setResendCount] = useState(0);

  useEffect(() => {
    if (seconds <= 0) return;
    const id = setInterval(() => setSeconds((s) => s - 1), 1000);
    return () => clearInterval(id);
  }, [seconds]);

  const onComplete = useCallback((code: string) => setOtp(code), []);

  const verify = async () => {
    if (otp.length !== 6) return;
    setError("");
    setLoading(true);
    try {
      await verifyOtp(email, otp, role);
      const href =
        `/(auth)/reset-password?email=${encodeURIComponent(email)}` +
        `&otp=${otp}&theme=${theme}&role=${encodeURIComponent(role)}` as Href;
      router.push(href);
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Invalid OTP";
      if (msg.toLowerCase().includes("expired")) {
        setError("OTP expired. Please resend.");
      } else {
        setError("Invalid OTP. Try again.");
      }
      runShake(shakeAnim);
    } finally {
      setLoading(false);
    }
  };

  const resend = async () => {
    if (resendCount >= 3) return;
    setError("");
    try {
      await sendForgotPasswordOtp(email, role);
      setResendCount((c) => c + 1);
      setSeconds(60);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Resend failed");
    }
  };

  const canVerify = otp.length === 6;

  return (
    <AuthFlowShell
      theme={theme}
      title="Verify OTP"
      subtitle={`Enter the 6-digit code sent to ${maskEmail(email)}`}
      icon="mail-open-outline"
      footer={
        <Pressable
          style={styles.footer}
          onPress={() => router.replace(loginPathForTheme(theme) as Href)}
        >
          <Text style={[styles.footerLink, { color: t.primary }]}>Back to Sign in</Text>
        </Pressable>
      }
    >
      <OtpInput theme={theme} onComplete={onComplete} shakeAnim={shakeAnim} />

      <View style={styles.resendRow}>
        {seconds > 0 ? (
          <Text style={styles.timer}>
            Resend OTP in 0:{seconds.toString().padStart(2, "0")}
          </Text>
        ) : resendCount >= 3 ? (
          <Text style={styles.error}>Too many attempts. Try again later.</Text>
        ) : (
          <Pressable onPress={resend}>
            <Text style={[styles.resendLink, { color: t.primary }]}>Resend OTP</Text>
          </Pressable>
        )}
      </View>

      <Pressable
        style={[
          styles.btn,
          { backgroundColor: canVerify ? t.primary : "#94A3B8" },
          loading && styles.btnDisabled,
        ]}
        onPress={verify}
        disabled={!canVerify || loading}
      >
        {loading ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.btnText}>Verify</Text>
        )}
      </Pressable>
      {error ? <Text style={styles.error}>{error}</Text> : null}
    </AuthFlowShell>
  );
}

const styles = StyleSheet.create({
  resendRow: { alignItems: "center", marginBottom: 16 },
  timer: { fontFamily: "Poppins_400Regular", color: colors.textSecondary, fontSize: 13 },
  resendLink: { fontFamily: "Poppins_600SemiBold", fontSize: 14 },
  btn: {
    borderRadius: 28,
    paddingVertical: 16,
    alignItems: "center",
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
  footer: { marginTop: 20, alignItems: "center" },
  footerLink: { fontFamily: "Poppins_600SemiBold" },
});
