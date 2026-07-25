import { Text, View } from "react-native";

interface PlaceholderListProps {
  title: string;
  description: string;
}

export function PlaceholderList({ title, description }: PlaceholderListProps) {
  return (
    <View className="rounded-2xl border border-dashed border-slate-300 bg-white p-6">
      <Text className="text-lg font-semibold text-slate-800">{title}</Text>
      <Text className="mt-2 leading-6 text-slate-500">{description}</Text>
    </View>
  );
}
