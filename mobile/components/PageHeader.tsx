import { Text, View } from "react-native";

interface PageHeaderProps {
  title: string;
  subtitle?: string;
}

export function PageHeader({ title, subtitle }: PageHeaderProps) {
  return (
    <View className="mb-4 mt-2">
      <Text className="text-2xl font-bold text-slate-900">{title}</Text>
      {subtitle ? (
        <Text className="mt-1 text-slate-500">{subtitle}</Text>
      ) : null}
    </View>
  );
}
