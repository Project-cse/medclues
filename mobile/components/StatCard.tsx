import { Text, View } from "react-native";

interface StatCardProps {
  label: string;
  value: string | number;
  accent?: string;
}

export function StatCard({ label, value, accent = "bg-primary-50" }: StatCardProps) {
  return (
    <View className={`flex-1 rounded-2xl p-4 ${accent}`}>
      <Text className="text-sm text-slate-600">{label}</Text>
      <Text className="mt-1 text-2xl font-bold text-slate-900">{value}</Text>
    </View>
  );
}
