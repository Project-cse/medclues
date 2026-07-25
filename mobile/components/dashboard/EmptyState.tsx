import { Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";

interface EmptyStateProps {
  icon?: keyof typeof Ionicons.glyphMap;
  title: string;
  message?: string;
}

export function EmptyState({
  icon = "file-tray-outline",
  title,
  message,
}: EmptyStateProps) {
  return (
    <View className="items-center justify-center rounded-2xl border border-dashed border-slate-200 bg-slate-50 py-10 px-6">
      <View className="mb-3 h-14 w-14 items-center justify-center rounded-full bg-primary-50">
        <Ionicons name={icon} size={28} color="#2563EB" />
      </View>
      <Text className="text-center text-base font-semibold text-slate-800">
        {title}
      </Text>
      {message ? (
        <Text className="mt-2 text-center text-sm text-slate-500">{message}</Text>
      ) : null}
    </View>
  );
}
