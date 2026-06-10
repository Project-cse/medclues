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
import { LoginScreenShell } from "@/components/auth/login/LoginScreenShell";
import { BrandHeaderText, BrandLogoMark } from "@/components/auth/login/BrandLogoMark";
import { AuthInput } from "@/components/auth/login/AuthInput";
import { SignInButton } from "@/components/auth/login/SignInButton";
import {
  StaffRoleSelector,
  type StaffRoleKey,
} from "@/components/auth/staff/StaffRoleSelector";
import { login } from "@/services/staffApi";
import { getPostLoginRoute } from "@/utils/authRoutes";
import { useToast } from "@/providers/ToastProvider";
import type { UserRole } from "@/types/api";

const RED = "#B91C1C";

export default function StaffLoginScreen() {
  const { showToast } = useToast();
  const [selectedRole, setSelectedRole] = useState<StaffRoleKey>("superAdmin");
  const [apiRole, setApiRole] = useState<UserRole>("admin");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [pwdFocused, setPwdFocused] = useState(false);

  const handleRoleSelect = (key: StaffRoleKey, role: UserRole) => {
    setSelectedRole(key);
    setApiRole(role);
  };

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
        role: apiRole,
      });
      showToast("Welcome back!", "success");
      router.replace(getPostLoginRoute(result.user.role));
    } catch (err) {
      showToast(err instanceof Error ? err.message : "Login failed", "error");
    } finally {
      setLoading(false);
    }
  };

  return (
    <LoginScreenShell variant="red">
      <Pressable
        style={styles.backBtn}
        onPress={() => router.replace("/(auth)/login-patient" as Href)}
        hitSlop={12}
      >
        <Ionicons name="arrow-back" size={22} color="#7F1D1D" />
      </Pressable>

      <View style={styles.header}>
        <BrandLogoMark variant="red" />
        <BrandHeaderText variant="red" />
      </View>

      <View style={styles.card}>
        <StaffRoleSelector selected={selectedRole} onSelect={handleRoleSelect} />

        <AuthInput
          label="Email Address"
          icon="mail-outline"
          theme="red"
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
            <Pressable
              onPress={() =>
                router.push(
                  `/(auth)/forgot-password?theme=red&role=${encodeURIComponent(apiRole)}` as Href
                )
              }
              hitSlop={8}
            >
              <Text style={styles.forgotLink}>Forgot Password?</Text>
            </Pressable>
          </View>
          <View style={[styles.inputRow, pwdFocused && styles.inputRowFocused]}>
            <Ionicons name="lock-closed-outline" size={18} color="#F87171" style={styles.leftIcon} />
            <TextInput
              style={styles.input}
              placeholder="Enter your password"
              placeholderTextColor="#D1D5DB"
              secureTextEntry={!showPassword}
              textContentType="password"
              autoComplete="password"
              value={password}
              onChangeText={setPassword}
              onFocus={() => setPwdFocused(true)}
              onBlur={() => setPwdFocused(false)}
            />
            <Pressable onPress={() => setShowPassword(!showPassword)} hitSlop={10}>
              <Ionicons
                name={showPassword ? "eye-off-outline" : "eye-outline"}
                size={20}
                color="#9CA3AF"
              />
            </Pressable>
          </View>
        </View>

        <SignInButton
          label="Login"
          variant="red"
          onPress={handleLogin}
          loading={loading}
        />
      </View>

      <Pressable
        onPress={() => router.replace("/(auth)/login-patient" as Href)}
        style={styles.patientLink}
      >
        <Ionicons name="person-outline" size={18} color="#F87171" />
        <Text style={styles.patientLinkText}>
          Back to <Text style={styles.patientLinkBold}>Patient login</Text>
        </Text>
      </Pressable>
    </LoginScreenShell>
  );
}

const styles = StyleSheet.create({
  backBtn: {
    alignSelf: "flex-start",
    marginLeft: 16,
    marginBottom: 4,
    padding: 6,
    backgroundColor: "rgba(255,255,255,0.7)",
    borderRadius: 20,
  },
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
    shadowColor: "#7F1D1D",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.1,
    shadowRadius: 24,
    elevation: 4,
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
    color: RED,
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
    borderColor: RED,
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
  patientLink: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
    marginTop: 16,
    paddingHorizontal: 16,
  },
  patientLinkText: {
    fontFamily: "Poppins_400Regular",
    fontSize: 14,
    color: "#6B7280",
  },
  patientLinkBold: {
    fontFamily: "Poppins_700Bold",
    color: RED,
  },
});
