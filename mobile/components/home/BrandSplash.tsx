import { useEffect } from "react";
import { StyleSheet, Text, View } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import Animated, {
  Easing,
  interpolate,
  runOnJS,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withTiming,
} from "react-native-reanimated";
import { brand } from "@/constants/theme";

export type BrandSplashVariant = "blue" | "red";

interface BrandSplashProps {
  onFinish: () => void;
  variant?: BrandSplashVariant;
}

const TITLE = "MediChain";

const VARIANT_CONFIG = {
  blue: {
    gradient: [brand.blueDark, brand.blue, "#1976D2"] as [string, string, string],
    accent: brand.cyan,
    glowBottom: "rgba(87, 210, 232, 0.12)",
    tagline: "Patient Management System",
    official: "Official Healthcare Platform",
  },
  red: {
    gradient: ["#7B241C", "#C0392B", "#E74C3C"] as [string, string, string],
    accent: "#F5B7B1",
    glowBottom: "rgba(245, 183, 177, 0.2)",
    tagline: "Hospital Administration",
    official: "Staff & Leadership Portal",
  },
};

function AnimatedLetter({
  letter,
  index,
  baseDelay,
  accent,
  accentColor,
}: {
  letter: string;
  index: number;
  baseDelay: number;
  accent?: boolean;
  accentColor?: string;
}) {
  const progress = useSharedValue(0);

  useEffect(() => {
    progress.value = withDelay(
      baseDelay + index * 55,
      withTiming(1, { duration: 380, easing: Easing.out(Easing.cubic) })
    );
  }, [baseDelay, index, progress]);

  const style = useAnimatedStyle(() => ({
    opacity: progress.value,
    transform: [
      { translateY: interpolate(progress.value, [0, 1], [18, 0]) },
      { scale: interpolate(progress.value, [0, 1], [0.92, 1]) },
    ],
  }));

  return (
    <Animated.Text
      style={[
        styles.letter,
        accent && styles.letterAccent,
        accent && accentColor ? { color: accentColor } : null,
        style,
      ]}
    >
      {letter}
    </Animated.Text>
  );
}

export function BrandSplash({ onFinish, variant = "blue" }: BrandSplashProps) {
  const cfg = VARIANT_CONFIG[variant];
  const lineWidth = useSharedValue(0);
  const taglineOpacity = useSharedValue(0);
  const taglineY = useSharedValue(12);
  const progressWidth = useSharedValue(0);
  const screenOpacity = useSharedValue(1);

  useEffect(() => {
    const titleEnd = TITLE.length * 55 + 120;

    lineWidth.value = withDelay(
      titleEnd,
      withTiming(1, { duration: 420, easing: Easing.out(Easing.cubic) })
    );

    taglineOpacity.value = withDelay(titleEnd + 180, withTiming(1, { duration: 400 }));
    taglineY.value = withDelay(
      titleEnd + 180,
      withTiming(0, { duration: 400, easing: Easing.out(Easing.cubic) })
    );

    progressWidth.value = withDelay(
      200,
      withTiming(1, { duration: 2000, easing: Easing.inOut(Easing.ease) })
    );

    const finishTimer = setTimeout(() => {
      screenOpacity.value = withTiming(0, { duration: 380 }, (done) => {
        if (done) runOnJS(onFinish)();
      });
    }, 2400);

    return () => clearTimeout(finishTimer);
  }, [lineWidth, onFinish, progressWidth, screenOpacity, taglineOpacity, taglineY]);

  const lineStyle = useAnimatedStyle(() => ({
    transform: [{ scaleX: lineWidth.value }],
    opacity: interpolate(lineWidth.value, [0, 0.3, 1], [0, 0.6, 1]),
  }));

  const taglineStyle = useAnimatedStyle(() => ({
    opacity: taglineOpacity.value,
    transform: [{ translateY: taglineY.value }],
  }));

  const barStyle = useAnimatedStyle(() => ({
    transform: [{ scaleX: progressWidth.value }],
  }));

  const screenStyle = useAnimatedStyle(() => ({
    opacity: screenOpacity.value,
  }));

  return (
    <Animated.View style={[styles.screen, screenStyle]}>
      <LinearGradient
        colors={cfg.gradient}
        start={{ x: 0.1, y: 0 }}
        end={{ x: 0.9, y: 1 }}
        style={StyleSheet.absoluteFill}
      />

      <View style={styles.glowTop} />
      <View style={[styles.glowBottom, { backgroundColor: cfg.glowBottom }]} />

      <View style={styles.center}>
        <View style={styles.titleRow}>
          {TITLE.split("").map((ch, i) => (
            <AnimatedLetter key={`${ch}-${i}`} letter={ch} index={i} baseDelay={80} />
          ))}
          <AnimatedLetter
            letter="+"
            index={TITLE.length}
            baseDelay={80}
            accent
            accentColor={cfg.accent}
          />
        </View>

        <Animated.View
          style={[styles.accentLine, lineStyle, { backgroundColor: cfg.accent }]}
        />

        <Animated.View style={taglineStyle}>
          <Text style={styles.tagline}>{cfg.tagline}</Text>
          <Text style={styles.official}>{cfg.official}</Text>
        </Animated.View>
      </View>

      <View style={styles.footer}>
        <View style={styles.progressTrack}>
          <Animated.View style={[styles.progressFill, barStyle]} />
        </View>
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  glowTop: {
    position: "absolute",
    top: -80,
    right: -40,
    width: 220,
    height: 220,
    borderRadius: 110,
    backgroundColor: "rgba(255,255,255,0.08)",
  },
  glowBottom: {
    position: "absolute",
    bottom: 120,
    left: -60,
    width: 180,
    height: 180,
    borderRadius: 90,
    backgroundColor: "rgba(87, 210, 232, 0.12)",
  },
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 28,
  },
  titleRow: {
    flexDirection: "row",
    alignItems: "flex-end",
    justifyContent: "center",
  },
  letter: {
    fontFamily: "Poppins_700Bold",
    fontSize: 42,
    color: brand.white,
    letterSpacing: 0.5,
    includeFontPadding: false,
  },
  letterAccent: {
    color: brand.cyan,
    fontSize: 44,
  },
  accentLine: {
    height: 3,
    width: 120,
    marginTop: 18,
    marginBottom: 22,
    borderRadius: 2,
    backgroundColor: brand.cyan,
    transformOrigin: "center",
  },
  tagline: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 15,
    color: "rgba(255,255,255,0.95)",
    textAlign: "center",
    letterSpacing: 0.4,
  },
  official: {
    marginTop: 8,
    fontFamily: "Poppins_400Regular",
    fontSize: 12,
    color: "rgba(255,255,255,0.72)",
    textAlign: "center",
    letterSpacing: 1.2,
    textTransform: "uppercase",
  },
  footer: {
    paddingHorizontal: 48,
    paddingBottom: 56,
  },
  progressTrack: {
    height: 3,
    borderRadius: 2,
    backgroundColor: "rgba(255,255,255,0.22)",
    overflow: "hidden",
  },
  progressFill: {
    height: "100%",
    width: "100%",
    borderRadius: 2,
    backgroundColor: brand.white,
    transformOrigin: "left",
  },
});
