import { Redirect, Stack } from "expo-router";
import { useAuth } from "@/hooks/useAuth";

export default function AdminLayout() {
  const { isAuthenticated, user } = useAuth();
  if (!isAuthenticated) return <Redirect href="/(auth)/login" />;
  if (user?.role !== "admin") return <Redirect href="/" />;
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="(tabs)" />
      <Stack.Screen name="doctors" />
      <Stack.Screen name="labs" />
      <Stack.Screen name="reports" />
      <Stack.Screen name="users" />
      <Stack.Screen name="notifications" />
      <Stack.Screen name="profile" />
      <Stack.Screen name="settings" />
      <Stack.Screen name="dashboard-detail" />
    </Stack>
  );
}
