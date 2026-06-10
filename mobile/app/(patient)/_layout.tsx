import { Redirect, Tabs } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useAuth } from "@/hooks/useAuth";
import { useAppTheme } from "@/hooks/useAppTheme";
import { isPatientRole, isStaffRole } from "@/utils/authRoutes";
import { DrawerProvider } from "@/contexts/DrawerContext";
import { PatientDrawer } from "@/components/layout/PatientDrawer";
import { shadows } from "@/constants/theme";

export default function PatientLayout() {
  const insets = useSafeAreaInsets();
  const { isAuthenticated, user } = useAuth();
  const { theme } = useAppTheme();

  if (!isAuthenticated) {
    return <Redirect href="/(auth)/login" />;
  }

  if (isStaffRole(user?.role)) {
    return <Redirect href="/(tabs)/dashboard" />;
  }

  if (!isPatientRole(user?.role)) {
    return <Redirect href="/" />;
  }

  return (
    <DrawerProvider>
      <Tabs
        screenOptions={{
          headerShown: false,
          tabBarActiveTintColor: theme.primary,
          tabBarInactiveTintColor: theme.textSecondary,
          tabBarStyle: {
            backgroundColor: theme.tabBar,
            borderTopWidth: 0,
            height: 56 + insets.bottom,
            paddingTop: 6,
            paddingBottom: insets.bottom + 4,
            ...shadows.tabBar,
          },
          tabBarLabelStyle: {
            fontFamily: "Poppins_600SemiBold",
            fontSize: 11,
          },
        }}
      >
        <Tabs.Screen
          name="home"
          options={{
            title: "Home",
            tabBarIcon: ({ color, size, focused }) => (
              <Ionicons name={focused ? "home" : "home-outline"} color={color} size={size} />
            ),
          }}
        />
        <Tabs.Screen
          name="appointments"
          options={{
            title: "Appointments",
            tabBarIcon: ({ color, size }) => (
              <Ionicons name="calendar" color={color} size={size} />
            ),
          }}
        />
        <Tabs.Screen
          name="records"
          options={{
            title: "Records",
            tabBarIcon: ({ color, size }) => (
              <Ionicons name="clipboard" color={color} size={size} />
            ),
          }}
        />
        <Tabs.Screen
          name="profile"
          options={{
            title: "Profile",
            tabBarIcon: ({ color, size }) => (
              <Ionicons name="person" color={color} size={size} />
            ),
          }}
        />
        <Tabs.Screen name="emergency" options={{ href: null }} />
        <Tabs.Screen name="payment-success" options={{ href: null }} />
        <Tabs.Screen name="payment-history" options={{ href: null }} />
        <Tabs.Screen name="booking-success" options={{ href: null }} />
        <Tabs.Screen name="settings" options={{ href: null }} />
        <Tabs.Screen name="personal-info" options={{ href: null }} />
        <Tabs.Screen name="address" options={{ href: null }} />
        <Tabs.Screen name="payment-methods" options={{ href: null }} />
        <Tabs.Screen name="notifications" options={{ href: null }} />
        <Tabs.Screen name="help" options={{ href: null }} />
        <Tabs.Screen name="appointment-detail" options={{ href: null }} />
      </Tabs>
      <PatientDrawer />
    </DrawerProvider>
  );
}
