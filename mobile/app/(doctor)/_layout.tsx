import { Redirect, Stack } from "expo-router";
import { useAuth } from "@/hooks/useAuth";

export default function DoctorLayout() {
  const { isAuthenticated, user } = useAuth();
  if (!isAuthenticated) return <Redirect href="/(auth)/login" />;
  if (user?.role !== "doctor") return <Redirect href="/" />;

  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="(tabs)" />
      <Stack.Screen name="schedule" />
      <Stack.Screen name="new-prescription" />
      <Stack.Screen name="medical-records" />
      <Stack.Screen name="earnings" />
      <Stack.Screen name="notifications" />
      <Stack.Screen name="profile" />
      <Stack.Screen name="settings" />
      <Stack.Screen name="patient-profile" />
    </Stack>
  );
}
