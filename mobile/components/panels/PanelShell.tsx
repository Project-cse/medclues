import { useState, type ReactNode } from "react";
import {
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { router, type Href } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { panelColors, panelShadow } from "@/constants/panelTheme";
import { logout } from "@/services/staffApi";

export type DrawerItem = {
  label: string;
  icon: keyof typeof Ionicons.glyphMap;
  href?: string;
  badge?: number;
  onPress?: () => void;
};

interface PanelShellProps {
  title?: string;
  children: ReactNode;
  drawerHeader: { name: string; subtitle: string };
  drawerItems: DrawerItem[];
  notificationCount?: number;
  onNotifications?: () => void;
  showMenu?: boolean;
}

export function PanelShell({
  title,
  children,
  drawerHeader,
  drawerItems,
  notificationCount = 0,
  onNotifications,
  showMenu = true,
}: PanelShellProps) {
  const [drawerOpen, setDrawerOpen] = useState(false);

  const navigate = (item: DrawerItem) => {
    setDrawerOpen(false);
    if (item.onPress) {
      item.onPress();
      return;
    }
    if (item.href) router.push(item.href as Href);
  };

  const handleLogout = async () => {
    setDrawerOpen(false);
    await logout();
    router.replace("/");
  };

  return (
    <SafeAreaView style={styles.safe} edges={["top", "left", "right"]}>
      <View style={styles.topBar}>
        {showMenu ? (
          <Pressable onPress={() => setDrawerOpen(true)} hitSlop={12}>
            <Ionicons name="menu" size={26} color={panelColors.textPrimary} />
          </Pressable>
        ) : (
          <View style={{ width: 26 }} />
        )}
        <Text style={styles.topTitle}>{title ?? ""}</Text>
        <Pressable onPress={onNotifications} hitSlop={12}>
          <Ionicons name="notifications-outline" size={24} color={panelColors.textPrimary} />
          {notificationCount > 0 ? (
            <View style={styles.badge}>
              <Text style={styles.badgeText}>
                {notificationCount > 9 ? "9+" : notificationCount}
              </Text>
            </View>
          ) : null}
        </Pressable>
      </View>

      {children}

      <Modal visible={drawerOpen} animationType="slide" transparent>
        <Pressable style={styles.overlay} onPress={() => setDrawerOpen(false)} />
        <View style={styles.drawer}>
          <SafeAreaView edges={["top", "bottom"]} style={{ flex: 1 }}>
            <View style={styles.drawerHeader}>
              <Text style={styles.drawerName}>{drawerHeader.name}</Text>
              <Text style={styles.drawerSub}>{drawerHeader.subtitle}</Text>
            </View>
            <ScrollView>
              {drawerItems.map((item) => (
                <Pressable
                  key={item.label}
                  style={styles.drawerRow}
                  onPress={() => navigate(item)}
                >
                  <Ionicons name={item.icon} size={22} color={panelColors.primary} />
                  <Text style={styles.drawerLabel}>{item.label}</Text>
                  {item.badge ? (
                    <View style={styles.drawerBadge}>
                      <Text style={styles.drawerBadgeText}>{item.badge}</Text>
                    </View>
                  ) : null}
                </Pressable>
              ))}
              <Pressable style={styles.drawerRow} onPress={handleLogout}>
                <Ionicons name="log-out-outline" size={22} color={panelColors.cancelled} />
                <Text style={[styles.drawerLabel, { color: panelColors.cancelled }]}>
                  Logout
                </Text>
              </Pressable>
            </ScrollView>
          </SafeAreaView>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: panelColors.background },
  topBar: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 16,
    paddingVertical: 10,
    backgroundColor: panelColors.card,
    borderBottomWidth: 1,
    borderBottomColor: panelColors.border,
  },
  topTitle: {
    flex: 1,
    textAlign: "center",
    fontFamily: "Poppins_600SemiBold",
    fontSize: 17,
    color: panelColors.textPrimary,
  },
  badge: {
    position: "absolute",
    top: -4,
    right: -6,
    backgroundColor: panelColors.cancelled,
    borderRadius: 10,
    minWidth: 18,
    height: 18,
    alignItems: "center",
    justifyContent: "center",
  },
  badgeText: { color: "#fff", fontSize: 10, fontWeight: "700" },
  overlay: { flex: 1, backgroundColor: "rgba(0,0,0,0.4)" },
  drawer: {
    position: "absolute",
    left: 0,
    top: 0,
    bottom: 0,
    width: "78%",
    maxWidth: 300,
    backgroundColor: panelColors.card,
    ...panelShadow,
  },
  drawerHeader: {
    padding: 20,
    backgroundColor: panelColors.primary,
  },
  drawerName: {
    fontFamily: "Poppins_700Bold",
    fontSize: 18,
    color: "#fff",
  },
  drawerSub: {
    fontFamily: "Poppins_400Regular",
    fontSize: 13,
    color: "rgba(255,255,255,0.85)",
    marginTop: 4,
  },
  drawerRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
    paddingVertical: 14,
    paddingHorizontal: 20,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: panelColors.border,
  },
  drawerLabel: {
    flex: 1,
    fontFamily: "Poppins_400Regular",
    fontSize: 15,
    color: panelColors.textPrimary,
  },
  drawerBadge: {
    backgroundColor: panelColors.cancelled,
    borderRadius: 10,
    paddingHorizontal: 8,
    paddingVertical: 2,
  },
  drawerBadgeText: { color: "#fff", fontSize: 11, fontWeight: "700" },
});
