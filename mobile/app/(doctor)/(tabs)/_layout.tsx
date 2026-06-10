import { Redirect, Tabs } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { panelColors } from "@/constants/panelTheme";
import { useAuth } from "@/hooks/useAuth";

export default function DoctorTabsLayout() {
  const { user } = useAuth();
  if (user?.role !== "doctor") return <Redirect href="/" />;

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: panelColors.primary,
        tabBarInactiveTintColor: panelColors.textSecondary,
        tabBarStyle: { height: 60, paddingBottom: 8, paddingTop: 6 },
      }}
    >
      <Tabs.Screen
        name="dashboard"
        options={{ title: "Dashboard", tabBarIcon: ({ color, size }) => <Ionicons name="home" size={size} color={color} /> }}
      />
      <Tabs.Screen
        name="appointments"
        options={{ title: "Appts", tabBarIcon: ({ color, size }) => <Ionicons name="calendar" size={size} color={color} /> }}
      />
      <Tabs.Screen
        name="patients"
        options={{ title: "Patients", tabBarIcon: ({ color, size }) => <Ionicons name="people" size={size} color={color} /> }}
      />
      <Tabs.Screen
        name="reports"
        options={{ title: "Reports", tabBarIcon: ({ color, size }) => <Ionicons name="bar-chart" size={size} color={color} /> }}
      />
      <Tabs.Screen
        name="more"
        options={{ title: "More", tabBarIcon: ({ color, size }) => <Ionicons name="menu" size={size} color={color} /> }}
      />
    </Tabs>
  );
}
