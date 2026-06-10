import { Redirect, Tabs } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { panelColors } from "@/constants/panelTheme";
import { useAuth } from "@/hooks/useAuth";

export default function DeanTabsLayout() {
  const { user } = useAuth();
  if (user?.role !== "dean") return <Redirect href="/" />;
  return (
    <Tabs screenOptions={{ headerShown: false, tabBarActiveTintColor: panelColors.primary, tabBarStyle: { height: 60 } }}>
      <Tabs.Screen name="dashboard" options={{ title: "Home", tabBarIcon: ({ color, size }) => <Ionicons name="home" size={size} color={color} /> }} />
      <Tabs.Screen name="students" options={{ title: "Students", tabBarIcon: ({ color, size }) => <Ionicons name="school" size={size} color={color} /> }} />
      <Tabs.Screen name="faculty" options={{ title: "Faculty", tabBarIcon: ({ color, size }) => <Ionicons name="people" size={size} color={color} /> }} />
      <Tabs.Screen name="more" options={{ title: "More", tabBarIcon: ({ color, size }) => <Ionicons name="menu" size={size} color={color} /> }} />
    </Tabs>
  );
}
