import { Redirect, Tabs } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { panelColors } from "@/constants/panelTheme";
import { useAuth } from "@/hooks/useAuth";

export default function AdminTabsLayout() {
  const { user } = useAuth();
  if (user?.role !== "admin") return <Redirect href="/" />;
  return (
    <Tabs screenOptions={{ headerShown: false, tabBarActiveTintColor: panelColors.primary, tabBarStyle: { height: 60 } }}>
      <Tabs.Screen name="dashboard" options={{ title: "Home", tabBarIcon: ({ color, size }) => <Ionicons name="home" size={size} color={color} /> }} />
      <Tabs.Screen name="appointments" options={{ title: "Appts", tabBarIcon: ({ color, size }) => <Ionicons name="calendar" size={size} color={color} /> }} />
      <Tabs.Screen name="patients" options={{ title: "Patients", tabBarIcon: ({ color, size }) => <Ionicons name="people" size={size} color={color} /> }} />
      <Tabs.Screen name="more" options={{ title: "More", tabBarIcon: ({ color, size }) => <Ionicons name="menu" size={size} color={color} /> }} />
    </Tabs>
  );
}
