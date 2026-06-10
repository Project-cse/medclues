import { Redirect, Stack } from "expo-router";
import { useAuth } from "@/hooks/useAuth";

export default function DeanLayout() {
  const { isAuthenticated, user } = useAuth();
  if (!isAuthenticated) return <Redirect href="/(auth)/login" />;
  if (user?.role !== "dean") return <Redirect href="/" />;
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="(tabs)" />
      <Stack.Screen name="departments" />
      <Stack.Screen name="approvals" />
      <Stack.Screen name="reports" />
      <Stack.Screen name="calendar" />
      <Stack.Screen name="notices" />
      <Stack.Screen name="messages" />
      <Stack.Screen name="profile" />
      <Stack.Screen name="settings" />
    </Stack>
  );
}
