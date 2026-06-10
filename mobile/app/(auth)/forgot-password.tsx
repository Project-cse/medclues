import { useLocalSearchParams } from "expo-router";
import { ForgotPasswordScreen } from "@/src/screens/auth/ForgotPasswordScreen";
import type { AuthThemeKey } from "@/src/utils/authTheme";

export default function ForgotPasswordRoute() {
  const params = useLocalSearchParams<{ theme?: string; role?: string }>();
  const theme = (params.theme === "red" ? "red" : "blue") as AuthThemeKey;
  const role = params.role ?? "patient";
  return <ForgotPasswordScreen theme={theme} role={role} />;
}
