import { type ReactNode } from "react";
import { Pressable, Text, View } from "react-native";

interface DashboardSectionProps {
  title: string;
  onViewAll?: () => void;
  children: ReactNode;
}

export function DashboardSection({
  title,
  onViewAll,
  children,
}: DashboardSectionProps) {
  return (
    <View className="mb-6 px-4">
      <View className="mb-3 flex-row items-center justify-between">
        <Text className="text-lg font-bold text-slate-900">{title}</Text>
        {onViewAll ? (
          <Pressable onPress={onViewAll} hitSlop={8}>
            <Text className="text-sm font-semibold text-primary-600">View All</Text>
          </Pressable>
        ) : null}
      </View>
      {children}
    </View>
  );
}
