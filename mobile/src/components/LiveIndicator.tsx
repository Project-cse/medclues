import { useEffect } from "react";
import { StyleSheet, Text, View } from "react-native";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withSequence,
  withTiming,
} from "react-native-reanimated";

export function LiveIndicator({ pulseKey }: { pulseKey?: number }) {
  const opacity = useSharedValue(1);

  useEffect(() => {
    opacity.value = withRepeat(
      withSequence(withTiming(0.35, { duration: 400 }), withTiming(1, { duration: 400 })),
      2,
      false
    );
  }, [pulseKey, opacity]);

  const dotStyle = useAnimatedStyle(() => ({ opacity: opacity.value }));

  return (
    <View style={styles.wrap}>
      <Animated.View style={[styles.dot, dotStyle]} />
      <Text style={styles.label}>Live</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { flexDirection: "row", alignItems: "center", gap: 6 },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: "#22C55E",
  },
  label: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 11,
    color: "#22C55E",
    letterSpacing: 0.5,
  },
});
