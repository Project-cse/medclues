import { useEffect, useRef, useState } from "react";
import {
  ActivityIndicator,
  Animated,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { router, type Href } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { AuthFlowShell } from "@/src/components/auth/AuthFlowShell";
import {
  PasswordStrengthBar,
  calcPasswordStrength,
} from "@/src/components/auth/PasswordStrengthBar";
import { resetPassword } from "@/src/api/auth";
import {
  getAuthTheme,
  loginPathForTheme,
  type AuthThemeKey,
} from "@/src/utils/authTheme";
import { colors } from "@/constants/theme";

type Props = {
  email: string;
  otp: string;
  theme: AuthThemeKey;
  role: string;
};

export function ResetPasswordScreen({ email, otp, theme, role }: Props) {
  const t = getAuthTheme(theme);
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [showPwd, setShowPwd] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  const checkScale = useRef(new Animated.Value(0)).current;
  const checkOpacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (!success) return;
    checkScale.setValue(0);
    checkOpacity.setValue(0);
    Animated.parallel([
      Animated.timing(checkScale, {
        toValue: 1,
        duration: 600,
        useNativeDriver: true,
      }),
      Animated.timing(checkOpacity, {
        toValue: 1,
        duration: 600,
        useNativeDriver: true,
      }),
    ]).start();
  }, [success, checkOpacity, checkScale]);

  const strength = calcPasswordStrength(password);

  const submit = async () => {
    setError("");
    if (!password || !confirm) {
      setError("Fill in both password fields");
      return;
    }
    if (password !== confirm) {
      setError("Passwords do not match");
      return;
    }
    if (strength.level === "Weak") {
      setError("Choose a stronger password (8+ chars, upper, number, symbol)");
      return;
    }
    setLoading(true);
    try {
      await resetPassword(email, otp, password, role);
      setSuccess(true);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Reset failed");
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <View style={styles.successScreen}>
        <Animated.View
          style={[
            styles.checkCircle,
            {
              opacity: checkOpacity,
              transform: [{ scale: checkScale }],
            },
          ]}
        >
          <Ionicons name="checkmark-circle" size={88} color="#22C55E" />
        </Animated.View>
        <Text style={styles.successTitle}>Password Reset Successfully!</Text>
        <Text style={styles.successSub}>
          You can now log in with your new password
        </Text>
        <Pressable
          style={[styles.btn, { backgroundColor: t.primary }]}
          onPress={() => router.replace(loginPathForTheme(theme) as Href)}
        >
          <Text style={styles.btnText}>Back to Login</Text>
        </Pressable>
      </View>
    );
  }

  return (
    <AuthFlowShell
      theme={theme}
      title="Reset Password"
      subtitle="Choose a strong new password"
      icon="lock-closed-outline"
    >
      <Text style={styles.label}>New Password</Text>
      <View style={styles.pwdRow}>
        <TextInput
          style={[styles.input, styles.inputFlex]}
          placeholder="New password"
          placeholderTextColor={colors.textSecondary}
          secureTextEntry={!showPwd}
          value={password}
          onChangeText={setPassword}
        />
        <Pressable onPress={() => setShowPwd(!showPwd)} style={styles.eye}>
          <Ionicons
            name={showPwd ? "eye-off-outline" : "eye-outline"}
            size={22}
            color={t.primary}
          />
        </Pressable>
      </View>
      <PasswordStrengthBar password={password} />

      <Text style={styles.label}>Confirm Password</Text>
      <View style={styles.pwdRow}>
        <TextInput
          style={[styles.input, styles.inputFlex]}
          placeholder="Confirm password"
          placeholderTextColor={colors.textSecondary}
          secureTextEntry={!showConfirm}
          value={confirm}
          onChangeText={setConfirm}
        />
        <Pressable onPress={() => setShowConfirm(!showConfirm)} style={styles.eye}>
          <Ionicons
            name={showConfirm ? "eye-off-outline" : "eye-outline"}
            size={22}
            color={t.primary}
          />
        </Pressable>
      </View>

      <Pressable
        style={[styles.btn, { backgroundColor: t.primary }, loading && styles.btnDisabled]}
        onPress={submit}
        disabled={loading}
      >
        {loading ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.btnText}>Reset Password</Text>
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
  },
  inputFlex: { flex: 1, marginBottom: 0 },
  pwdRow: { flexDirection: "row", alignItems: "center", marginBottom: 14 },
  eye: { position: "absolute", right: 14 },
  btn: {
    borderRadius: 28,
    paddingVertical: 16,
    alignItems: "center",
    marginTop: 8,
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
  successScreen: {
    flex: 1,
    backgroundColor: colors.background,
    alignItems: "center",
    justifyContent: "center",
    padding: 28,
  },
  checkCircle: { marginBottom: 20 },
  successTitle: {
    fontFamily: "Poppins_700Bold",
    fontSize: 22,
    color: colors.textPrimary,
    textAlign: "center",
  },
  successSub: {
    fontFamily: "Poppins_400Regular",
    color: colors.textSecondary,
    marginTop: 8,
    marginBottom: 28,
    textAlign: "center",
  },
});
