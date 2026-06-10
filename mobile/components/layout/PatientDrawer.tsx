import {
  Animated,
  Dimensions,
  Modal,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useEffect, useRef } from "react";
import { router, type Href } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useDrawer } from "@/contexts/DrawerContext";
import { useAuthStore } from "@/store/authStore";
import { useAppTheme } from "@/hooks/useAppTheme";
import { AvatarImage } from "@/components/ui/AvatarImage";
import { logout } from "@/services/staffApi";

const WIDTH = Math.min(Dimensions.get("window").width * 0.82, 300);

const ITEMS: { label: string; icon: keyof typeof Ionicons.glyphMap; href: string }[] = [
  { label: "Home", icon: "home-outline", href: "/(patient)/home" },
  { label: "Hospitals", icon: "business-outline", href: "/hospitals" },
  { label: "Doctors", icon: "medical-outline", href: "/doctors" },
  { label: "Appointments", icon: "calendar-outline", href: "/(patient)/appointments" },
  { label: "Records", icon: "clipboard-outline", href: "/(patient)/records" },
  { label: "Profile", icon: "person-outline", href: "/(patient)/profile" },
  { label: "Settings", icon: "settings-outline", href: "/(patient)/settings" },
];

export function PatientDrawer() {
  const { isOpen, closeDrawer } = useDrawer();
  const { theme } = useAppTheme();
  const insets = useSafeAreaInsets();
  const user = useAuthStore((s) => s.user);
  const slide = useRef(new Animated.Value(-WIDTH)).current;

  useEffect(() => {
    Animated.timing(slide, {
      toValue: isOpen ? 0 : -WIDTH,
      duration: 220,
      useNativeDriver: true,
    }).start();
  }, [isOpen, slide]);

  const navigate = (href: string) => {
    closeDrawer();
    router.push(href as Href);
  };

  return (
    <Modal visible={isOpen} transparent animationType="none" onRequestClose={closeDrawer}>
      <Pressable style={styles.backdrop} onPress={closeDrawer} />
      <Animated.View
        style={[
          styles.panel,
          {
            backgroundColor: theme.surface,
            paddingTop: insets.top + 12,
            paddingBottom: insets.bottom + 12,
            transform: [{ translateX: slide }],
          },
        ]}
      >
        <View style={[styles.profile, { borderBottomColor: theme.border }]}>
          <AvatarImage uri={user?.image} size={64} />
          <Text style={[styles.name, { color: theme.text }]}>{user?.name ?? "User"}</Text>
          <Text style={[styles.email, { color: theme.textSecondary }]}>{user?.email ?? ""}</Text>
        </View>

        {ITEMS.map((item) => (
          <Pressable
            key={item.label}
            style={[styles.row, { borderBottomColor: theme.border }]}
            onPress={() => navigate(item.href)}
          >
            <Ionicons name={item.icon} size={22} color={theme.primary} />
            <Text style={[styles.rowLabel, { color: theme.text }]}>{item.label}</Text>
          </Pressable>
        ))}

        <Pressable
          style={styles.logout}
          onPress={async () => {
            closeDrawer();
            await logout();
            router.replace("/");
          }}
        >
          <Ionicons name="log-out-outline" size={22} color={theme.red} />
          <Text style={[styles.logoutText, { color: theme.red }]}>Logout</Text>
        </Pressable>
      </Animated.View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(15, 23, 42, 0.45)",
  },
  panel: {
    position: "absolute",
    left: 0,
    top: 0,
    bottom: 0,
    width: WIDTH,
    shadowColor: "#000",
    shadowOpacity: 0.2,
    shadowRadius: 12,
    elevation: 16,
  },
  profile: {
    paddingHorizontal: 20,
    paddingBottom: 16,
    borderBottomWidth: 1,
    alignItems: "flex-start",
  },
  name: {
    marginTop: 12,
    fontFamily: "Poppins_700Bold",
    fontSize: 18,
  },
  email: {
    marginTop: 4,
    fontFamily: "Poppins_400Regular",
    fontSize: 13,
  },
  row: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 20,
    paddingVertical: 14,
    borderBottomWidth: 1,
    gap: 14,
  },
  rowLabel: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 16,
  },
  logout: {
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
    paddingHorizontal: 20,
    paddingVertical: 18,
    marginTop: 8,
  },
  logoutText: {
    fontFamily: "Poppins_700Bold",
    fontSize: 16,
  },
});
