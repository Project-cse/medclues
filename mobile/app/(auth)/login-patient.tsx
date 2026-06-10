import { useState } from "react";
import {
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { router, type Href } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { useQueryClient } from "@tanstack/react-query";
import { LoginScreenShell } from "@/components/auth/login/LoginScreenShell";
import { BrandHeaderText, BrandLogoMark } from "@/components/auth/login/BrandLogoMark";
import { AuthInput } from "@/components/auth/login/AuthInput";
import { SignInButton } from "@/components/auth/login/SignInButton";
import { PatientGoogleSignIn } from "@/components/auth/PatientGoogleSignIn";
import { login } from "@/services/staffApi";
import { prefetchPatientData } from "@/hooks/usePatientData";
import { getPostLoginRoute } from "@/utils/authRoutes";
import { useToast } from "@/providers/ToastProvider";

const PRIMARY = "#2563EB";

export default function PatientLoginScreen() {
  const queryClient = useQueryClient();
  const { showToast } = useToast();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPwd, setShowPwd] = useState(false);
  const [loading, setLoading] = useState(false);
  const [pwdFocused, setPwdFocused] = useState(false);

  const handleLogin = async () => {
    if (!email.trim() || !password) {
      showToast("Enter email and password", "error");
      return;
    }
    setLoading(true);
    try {
      const result = await login({
        email: email.trim(),
        password,
        role: "patient",
      });
      await prefetchPatientData(queryClient);
      showToast("Welcome back!", "success");
      router.replace(getPostLoginRoute(result.user.role));
    } catch (err) {
      showToast(err instanceof Error ? err.message : "Login failed", "error");
    } finally {
      setLoading(false);
    }
  };

  return (
    <LoginScreenShell variant="blue">
      <View style={styles.header}>
        <BrandLogoMark />
        <BrandHeaderText />
      </View>

      <View style={styles.card}>
        <View style={styles.roleRow}>
          <View style={styles.roleAvatar}>
            <Ionicons name="person" size={24} color={PRIMARY} />
          </View>
          <View style={styles.roleText}>
            <Text style={styles.roleTitle}>Patient</Text>
            <Text style={styles.roleSub}>
              Book appointments & view your health records
            </Text>
          </View>
        </View>

        <AuthInput
          label="Email Address"
          icon="mail-outline"
          placeholder="Enter your email"
          autoCapitalize="none"
          keyboardType="email-address"
          textContentType="emailAddress"
          autoComplete="email"
          value={email}
          onChangeText={setEmail}
        />

        <View style={styles.pwdBlock}>
          <View style={styles.pwdLabelRow}>
            <Text style={styles.fieldLabel}>Password</Text>
            <Pressable onPress={() => router.push("/(auth)/forgot-password?theme=blue&role=patient" as Href)} hitSlop={8}>
              <Text style={styles.forgotLink}>Forgot Password?</Text>
            </Pressable>
          </View>
          <View style={[styles.inputRow, pwdFocused && styles.inputRowFocused]}>
            <Ionicons name="lock-closed-outline" size={18} color="#9CA3AF" style={styles.leftIcon} />
            <TextInput
              style={styles.input}
              placeholder="Enter your password"
              placeholderTextColor="#D1D5DB"
              secureTextEntry={!showPwd}
              textContentType="password"
              autoComplete="password"
              value={password}
              onChangeText={setPassword}
              onFocus={() => setPwdFocused(true)}
              onBlur={() => setPwdFocused(false)}
            />
            <Pressable onPress={() => setShowPwd(!showPwd)} hitSlop={10}>
              <Ionicons name={showPwd ? "eye-off-outline" : "eye-outline"} size={20} color="#9CA3AF" />
            </Pressable>
          </View>
        </View>

        <SignInButton
          label="Sign In"
          variant="blue"
          onPress={handleLogin}
          loading={loading}
        />

        <View style={styles.orRow}>
          <View style={styles.orLine} />
          <Text style={styles.orText}>OR CONTINUE WITH</Text>
          <View style={styles.orLine} />
        </View>

        <PatientGoogleSignIn />
      </View>

      <Pressable onPress={() => router.push("/(auth)/register")} style={styles.register}>
        <Text style={styles.registerText}>
          Don&apos;t have an account? <Text style={styles.registerLink}>Register</Text>
        </Text>
      </Pressable>

      <Pressable style={styles.staffLink} onPress={() => router.push("/(auth)/login-staff" as Href)}>
        <Text style={styles.staffLinkText}>
          Hospital staff? <Text style={styles.registerLink}>Admin panel</Text>
        </Text>
      </Pressable>
    </LoginScreenShell>
  );
}

const styles = StyleSheet.create({
  header: {
    alignItems: "center",
    paddingHorizontal: 16,
  },
  card: {
    backgroundColor: "#fff",
    borderRadius: 24,
    marginHorizontal: 16,
    marginTop: 16,
    padding: 24,
    overflow: "visible",
    shadowColor: "#1E3A5F",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.1,
    shadowRadius: 24,
    elevation: 4,
  },
  roleRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    marginBottom: 20,
  },
  roleAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: "#DBEAFE",
    alignItems: "center",
    justifyContent: "center",
  },
  roleText: { flex: 1 },
  roleTitle: {
    fontFamily: "Poppins_700Bold",
    fontSize: 16,
    color: PRIMARY,
  },
  roleSub: {
    fontFamily: "Poppins_400Regular",
    fontSize: 12,
    color: "#9CA3AF",
    marginTop: 2,
  },
  pwdBlock: { marginBottom: 16 },
  pwdLabelRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 8,
  },
  fieldLabel: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 14,
    color: "#1F2937",
  },
  forgotLink: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 14,
    color: PRIMARY,
  },
  inputRow: {
    flexDirection: "row",
    alignItems: "center",
    borderWidth: 1,
    borderColor: "#E5E7EB",
    borderRadius: 12,
    backgroundColor: "#fff",
    paddingHorizontal: 12,
    minHeight: 48,
  },
  inputRowFocused: {
    borderColor: PRIMARY,
    borderWidth: 2,
  },
  leftIcon: { marginRight: 8 },
  input: {
    flex: 1,
    fontFamily: "Poppins_400Regular",
    fontSize: 15,
    color: "#111827",
    paddingVertical: 12,
  },
  orRow: {
    flexDirection: "row",
    alignItems: "center",
    marginVertical: 16,
    gap: 8,
  },
  orLine: { flex: 1, height: 1, backgroundColor: "#E5E7EB" },
  orText: {
    fontFamily: "Poppins_400Regular",
    fontSize: 11,
    color: "#9CA3AF",
    letterSpacing: 0.5,
  },
  register: {
    alignItems: "center",
    marginTop: 16,
    paddingHorizontal: 16,
  },
  registerText: {
    fontFamily: "Poppins_400Regular",
    fontSize: 14,
    color: "#6B7280",
  },
  registerLink: {
    fontFamily: "Poppins_700Bold",
    color: PRIMARY,
  },
  staffLink: {
    alignItems: "center",
    marginTop: 10,
  },
  staffLinkText: {
    fontFamily: "Poppins_400Regular",
    fontSize: 13,
    color: "#6B7280",
  },
});
