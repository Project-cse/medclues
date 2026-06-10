import { Redirect, Stack } from "expo-router";
import { useAuth } from "@/hooks/useAuth";
import { getPostLoginRoute } from "@/utils/authRoutes";

export default function AuthLayout() {
  const { isAuthenticated, user } = useAuth();

  if (isAuthenticated && user?.role) {
    return <Redirect href={getPostLoginRoute(user.role)} />;
  }

  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="login" />
      <Stack.Screen name="register" />
      <Stack.Screen name="login-patient" />
      <Stack.Screen name="login-staff" />
      <Stack.Screen
        name="forgot-password"
        options={{ presentation: "modal", animation: "slide_from_bottom" }}
      />
      <Stack.Screen
        name="otp-verify"
        options={{ presentation: "modal", animation: "slide_from_bottom" }}
      />
      <Stack.Screen
        name="reset-password"
        options={{ presentation: "modal", animation: "slide_from_bottom" }}
      />
    </Stack>
  );
}
