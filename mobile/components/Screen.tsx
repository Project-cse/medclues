import { ReactNode } from "react";
import { ScrollView, View, ViewProps } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

interface ScreenProps extends ViewProps {
  children: ReactNode;
  scroll?: boolean;
  className?: string;
}

export function Screen({
  children,
  scroll = true,
  className = "",
  ...props
}: ScreenProps) {
  const content = (
    <View className={`flex-1 bg-slate-50 px-4 pt-2 ${className}`} {...props}>
      {children}
    </View>
  );

  return (
    <SafeAreaView className="flex-1 bg-slate-50" edges={["top", "left", "right"]}>
      {scroll ? (
        <ScrollView
          className="flex-1"
          contentContainerClassName="pb-8"
          showsVerticalScrollIndicator={false}
        >
          {content}
        </ScrollView>
      ) : (
        <View className="flex-1">{content}</View>
      )}
    </SafeAreaView>
  );
}
