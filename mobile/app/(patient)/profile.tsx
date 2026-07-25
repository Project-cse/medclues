import { useState } from "react";
import {
  ActivityIndicator,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { router, type Href } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import * as ImagePicker from "expo-image-picker";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useMe } from "@/hooks/useMe";
import { authService } from "@/services/auth";
import { logout } from "@/services/staffApi";
import { useAuthStore } from "@/store/authStore";
import { useToast } from "@/providers/ToastProvider";
import { useAppTheme } from "@/hooks/useAppTheme";
import { AvatarImage } from "@/components/ui/AvatarImage";
import { ScreenLoader } from "@/components/animations/ScreenLoader";
import { ErrorState } from "@/components/ui/ErrorState";
import { shadows } from "@/constants/theme";

type MenuItem = {
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  color: string;
  bg: string;
  href: string;
};

const MENU: MenuItem[] = [
  {
    icon: "person-outline",
    label: "Personal Information",
    color: "#0EA5E9",
    bg: "#EFF6FF",
    href: "/(patient)/personal-info",
  },
  {
    icon: "location-outline",
    label: "Address",
    color: "#6366F1",
    bg: "#EEF2FF",
    href: "/(patient)/address",
  },
  {
    icon: "receipt-outline",
    label: "Payment History",
    color: "#10B981",
    bg: "#ECFDF5",
    href: "/(patient)/payment-history",
  },
  {
    icon: "card-outline",
    label: "Payment Methods",
    color: "#10B981",
    bg: "#ECFDF5",
    href: "/(patient)/payment-methods",
  },
  {
    icon: "notifications-outline",
    label: "Notifications",
    color: "#F97316",
    bg: "#FFF7ED",
    href: "/(patient)/notifications",
  },
  {
    icon: "settings-outline",
    label: "Settings",
    color: "#64748B",
    bg: "#F1F5F9",
    href: "/(patient)/settings",
  },
  {
    icon: "help-circle-outline",
    label: "Help & Support",
    color: "#0EA5E9",
    bg: "#EFF6FF",
    href: "/(patient)/help",
  },
];

function formatAddress(addr: unknown): string {
  if (!addr) return "";
  if (typeof addr === "string") return addr;
  if (typeof addr === "object" && addr !== null) {
    const a = addr as { line1?: string; line2?: string };
    return [a.line1, a.line2].filter(Boolean).join(", ");
  }
  return "";
}

export default function ProfileScreen() {
  const { theme } = useAppTheme();
  const { showToast } = useToast();
  const queryClient = useQueryClient();
  const updateUser = useAuthStore((s) => s.updateUser);
  const [uploading, setUploading] = useState(false);
  const { data: me, isLoading, error, refetch, isRefetching } = useMe();

  const uploadMutation = useMutation({
    mutationFn: (uri: string) => authService.uploadProfilePic(uri),
    onSuccess: async ({ profilePicUrl }) => {
      if (profilePicUrl) {
        await updateUser({ image: profilePicUrl });
      }
      await queryClient.invalidateQueries({ queryKey: ["me"] });
      showToast("Photo updated successfully!", "success");
    },
    onError: (err) => {
      showToast(err instanceof Error ? err.message : "Upload failed", "error");
    },
  });

  const handlePickImage = async () => {
    try {
      const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (!permission.granted) {
        showToast("Please allow photo access in settings", "error");
        return;
      }

      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ["images"],
        allowsEditing: true,
        aspect: [1, 1],
        quality: 0.8,
      });

      if (result.canceled || !result.assets[0]) return;

      setUploading(true);
      await uploadMutation.mutateAsync(result.assets[0].uri);
    } catch (e) {
      showToast(e instanceof Error ? e.message : "Upload failed", "error");
    } finally {
      setUploading(false);
    }
  };

  const handleLogout = async () => {
    await logout();
    router.replace("/");
  };

  if (isLoading) {
    return <ScreenLoader message="Loading profile..." />;
  }

  if (error) {
    return (
      <SafeAreaView style={[styles.safe, { backgroundColor: theme.background }]}>
        <ErrorState
          message={error instanceof Error ? error.message : "Failed to load profile"}
          onRetry={() => refetch()}
        />
      </SafeAreaView>
    );
  }

  const safeName = me?.name?.trim() || "User";
  const addressStr = formatAddress(me?.address);

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: theme.background }]} edges={["top"]}>
      <ScrollView
        contentContainerStyle={styles.scroll}
        refreshControl={
          <RefreshControl
            refreshing={isRefetching}
            onRefresh={refetch}
            tintColor={theme.primary}
          />
        }
      >
        <View style={styles.hero}>
          <Pressable onPress={handlePickImage} disabled={uploading}>
            <View style={styles.avatarWrap}>
              <AvatarImage uri={me?.profilePicUrl} size={110} />
              <View style={[styles.cameraBadge, { backgroundColor: theme.primary }]}>
                {uploading ? (
                  <ActivityIndicator size="small" color="#fff" />
                ) : (
                  <Ionicons name="camera" size={16} color="#fff" />
                )}
              </View>
            </View>
          </Pressable>
          <Text style={[styles.name, { color: theme.text }]}>{safeName.toUpperCase()}</Text>
          <Text style={[styles.meta, { color: theme.textSecondary }]}>
            {me?.phone ?? "Phone not set"}
          </Text>
          <Text style={[styles.meta, { color: theme.textSecondary }]}>
            {me?.email ?? "Email not set"}
          </Text>
          {me?.bloodGroup ? (
            <Text style={[styles.meta, { color: theme.textSecondary }]}>
              Blood group: {me.bloodGroup}
            </Text>
          ) : null}
          {addressStr ? (
            <Text style={[styles.meta, { color: theme.textSecondary }]}>{addressStr}</Text>
          ) : null}
        </View>

        <View
          style={[
            styles.menuCard,
            shadows.card,
            { backgroundColor: theme.surface, borderColor: theme.border },
          ]}
        >
          {MENU.map((item, i) => (
            <Pressable
              key={item.label}
              style={[
                styles.menuRow,
                i < MENU.length - 1 && {
                  borderBottomWidth: 1,
                  borderBottomColor: theme.border,
                },
              ]}
              onPress={() => router.push(item.href as Href)}
            >
              <View style={[styles.menuIcon, { backgroundColor: item.bg }]}>
                <Ionicons name={item.icon} size={22} color={item.color} />
              </View>
              <Text style={[styles.menuLabel, { color: theme.text }]}>{item.label}</Text>
              <Ionicons name="chevron-forward" size={20} color={theme.textSecondary} />
            </Pressable>
          ))}
        </View>

        <Pressable style={styles.logout} onPress={handleLogout}>
          <Ionicons name="log-out-outline" size={22} color={theme.red} />
          <Text style={[styles.logoutText, { color: theme.red }]}>Logout</Text>
        </Pressable>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  scroll: { paddingBottom: 32 },
  hero: { alignItems: "center", paddingVertical: 24 },
  avatarWrap: { position: "relative" },
  cameraBadge: {
    position: "absolute",
    bottom: 4,
    right: 4,
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 2,
    borderColor: "#fff",
  },
  name: {
    marginTop: 14,
    fontFamily: "Poppins_700Bold",
    fontSize: 22,
  },
  meta: {
    fontFamily: "Poppins_400Regular",
    fontSize: 14,
    marginTop: 4,
    textAlign: "center",
    paddingHorizontal: 24,
  },
  menuCard: {
    marginHorizontal: 16,
    borderRadius: 16,
    overflow: "hidden",
    borderWidth: 1,
  },
  menuRow: {
    flexDirection: "row",
    alignItems: "center",
    padding: 16,
    gap: 12,
  },
  menuIcon: {
    width: 42,
    height: 42,
    borderRadius: 12,
    alignItems: "center",
    justifyContent: "center",
  },
  menuLabel: {
    flex: 1,
    fontFamily: "Poppins_600SemiBold",
    fontSize: 15,
  },
  logout: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    marginTop: 24,
    padding: 16,
  },
  logoutText: {
    fontFamily: "Poppins_700Bold",
    fontSize: 16,
  },
});
