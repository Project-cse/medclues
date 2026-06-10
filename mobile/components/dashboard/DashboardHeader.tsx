import { Pressable, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { formatDashboardGreeting } from "@/utils/greeting";
import type { UserRole } from "@/types/api";

interface DashboardHeaderProps {
  name: string;
  role?: UserRole | null;
  branchName: string;
  notificationCount: number;
  onNotificationsPress: () => void;
  onProfilePress?: () => void;
}

export function DashboardHeader({
  name,
  role,
  branchName,
  notificationCount,
  onNotificationsPress,
  onProfilePress,
}: DashboardHeaderProps) {
  const initials = name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

  return (
    <View className="flex-row items-start justify-between px-4 pb-4 pt-2">
      <View className="flex-1 pr-3">
        <Text className="text-2xl font-bold text-slate-900">
          {formatDashboardGreeting(name, role)}
        </Text>
        <View className="mt-1 flex-row items-center gap-1">
          <Ionicons name="business-outline" size={14} color="#64748b" />
          <Text className="text-sm text-slate-500">{branchName}</Text>
        </View>
      </View>

      <View className="flex-row items-center gap-2">
        <Pressable
          onPress={onNotificationsPress}
          className="relative h-11 w-11 items-center justify-center rounded-full bg-white shadow-sm"
        >
          <Ionicons name="notifications-outline" size={22} color="#2563EB" />
          {notificationCount > 0 ? (
            <View className="absolute -right-0.5 -top-0.5 min-h-[18px] min-w-[18px] items-center justify-center rounded-full bg-red-500 px-1">
              <Text className="text-[10px] font-bold text-white">
                {notificationCount > 9 ? "9+" : notificationCount}
              </Text>
            </View>
          ) : null}
        </Pressable>

        <Pressable
          onPress={onProfilePress}
          className="h-11 w-11 items-center justify-center rounded-full bg-primary-600"
        >
          <Text className="text-sm font-bold text-white">{initials || "?"}</Text>
        </Pressable>
      </View>
    </View>
  );
}
