import { useLocalSearchParams } from "expo-router";
import { OtpVerifyScreen } from "@/src/screens/auth/OtpVerifyScreen";
import type { AuthThemeKey } from "@/src/utils/authTheme";

export default function OtpVerifyRoute() {
  const params = useLocalSearchParams<{ email?: string; theme?: string; role?: string }>();
  const theme = (params.theme === "red" ? "red" : "blue") as AuthThemeKey;
  return (
    <OtpVerifyScreen
      email={params.email ?? ""}
      theme={theme}
      role={params.role ?? "patient"}
    />
  );
}
