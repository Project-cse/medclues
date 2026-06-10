import { useEffect } from "react";
import { StyleSheet, Text, View } from "react-native";
import * as SplashScreen from "expo-splash-screen";
import { AmbulanciaLottie } from "@/components/lottie/AmbulanciaLottie";

type Props = {
  onFinish: () => void;
  minDurationMs?: number;
};

export function AmbulanciaStartupSplash({ onFinish, minDurationMs = 2200 }: Props) {
  useEffect(() => {
    SplashScreen.hideAsync().catch(() => undefined);
    const timer = setTimeout(onFinish, minDurationMs);
    return () => clearTimeout(timer);
  }, [minDurationMs, onFinish]);

  return (
    <View style={styles.screen}>
      <AmbulanciaLottie width={280} height={280} loop autoPlay />
      <Text style={styles.title}>MediChain+</Text>
      <Text style={styles.tagline}>Your Health, Our Priority</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#FFFFFF",
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
  },
  title: {
    marginTop: 16,
    fontFamily: "Poppins_700Bold",
    fontSize: 28,
    color: "#0EA5E9",
  },
  tagline: {
    marginTop: 8,
    fontFamily: "Poppins_400Regular",
    fontSize: 14,
    color: "#64748B",
  },
});
