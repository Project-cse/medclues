import { useLocalSearchParams } from "expo-router";
import { ResetPasswordScreen } from "@/src/screens/auth/ResetPasswordScreen";
import type { AuthThemeKey } from "@/src/utils/authTheme";

export default function ResetPasswordRoute() {
  const params = useLocalSearchParams<{
    email?: string;
    otp?: string;
    theme?: string;
    role?: string;
  }>();
  const theme = (params.theme === "red" ? "red" : "blue") as AuthThemeKey;
  return (
    <ResetPasswordScreen
      email={params.email ?? ""}
      otp={params.otp ?? ""}
      theme={theme}
      role={params.role ?? "patient"}
    />
  );
}
