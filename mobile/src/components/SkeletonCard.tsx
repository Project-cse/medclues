import { useEffect } from "react";
import { StyleSheet, View } from "react-native";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
} from "react-native-reanimated";
import { panelColors } from "@/constants/panelTheme";

export function SkeletonCard({ height = 180 }: { height?: number }) {
  const opacity = useSharedValue(0.45);

  useEffect(() => {
    opacity.value = withRepeat(withTiming(0.9, { duration: 700 }), -1, true);
  }, [opacity]);

  const anim = useAnimatedStyle(() => ({ opacity: opacity.value }));

  return (
    <Animated.View style={[styles.card, { height }, anim]}>
      <View style={styles.lineLong} />
      <View style={styles.lineShort} />
      <View style={styles.block} />
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  card: {
    marginHorizontal: 16,
    marginBottom: 12,
    borderRadius: 14,
    backgroundColor: panelColors.card,
    borderWidth: 1,
    borderColor: panelColors.border,
    padding: 16,
    justifyContent: "flex-end",
    gap: 10,
  },
  lineLong: {
    height: 12,
    width: "70%",
    borderRadius: 6,
    backgroundColor: "#E2E8F0",
  },
  lineShort: {
    height: 10,
    width: "40%",
    borderRadius: 5,
    backgroundColor: "#E2E8F0",
  },
  block: {
    flex: 1,
    borderRadius: 10,
    backgroundColor: "#F1F5F9",
    marginTop: 8,
  },
});
