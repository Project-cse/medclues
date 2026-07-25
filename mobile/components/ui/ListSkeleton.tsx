import { StyleSheet, View } from "react-native";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
} from "react-native-reanimated";
import { useEffect } from "react";
import { colors } from "@/constants/theme";

export function ListSkeleton({ rows = 3 }: { rows?: number }) {
  const opacity = useSharedValue(0.4);

  useEffect(() => {
    opacity.value = withRepeat(withTiming(1, { duration: 800 }), -1, true);
  }, [opacity]);

  const animStyle = useAnimatedStyle(() => ({ opacity: opacity.value }));

  return (
    <View style={styles.wrap}>
      {Array.from({ length: rows }).map((_, i) => (
        <Animated.View key={i} style={[styles.card, animStyle]} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { paddingHorizontal: 16, gap: 12 },
  card: {
    height: 120,
    backgroundColor: colors.border,
    borderRadius: 16,
  },
});
