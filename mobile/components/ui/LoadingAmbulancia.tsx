import { StyleSheet, Text, View } from "react-native";
import { AmbulanciaLottie } from "@/components/lottie/AmbulanciaLottie";

type Props = {
  visible: boolean;
  message?: string;
  size?: number;
};

/**
 * In-screen loading overlay (NOT a Modal — keeps Lottie visible on Android).
 */
export function LoadingAmbulancia({
  visible,
  message = "Please wait…",
  size = 180,
}: Props) {
  if (!visible) return null;

  return (
    <View style={styles.overlay} pointerEvents="auto">
      <View style={styles.panel}>
        <AmbulanciaLottie width={size} height={size} loop autoPlay />
        {message ? <Text style={styles.text}>{message}</Text> : null}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: {
    ...StyleSheet.absoluteFillObject,
    zIndex: 1000,
    elevation: 1000,
    backgroundColor: "rgba(15, 23, 42, 0.35)",
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
  },
  panel: {
    alignItems: "center",
    justifyContent: "center",
    padding: 20,
    borderRadius: 20,
    backgroundColor: "rgba(255, 255, 255, 0.92)",
    maxWidth: 320,
    width: "100%",
  },
  text: {
    marginTop: 8,
    fontFamily: "Poppins_600SemiBold",
    fontSize: 15,
    color: "#374151",
    textAlign: "center",
  },
});
