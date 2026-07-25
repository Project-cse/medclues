import { StyleSheet, View } from "react-native";

type Variant = "blue" | "red";

const BLOB_COLORS: Record<Variant, [string, string]> = {
  blue: ["#C7D9F5", "#D6E8FF"],
  red: ["#FECACA", "#FEE2E2"],
};

/** Static background blobs — no animation (avoids keyboard dismiss on Android) */
export function LoginBlobs({ variant = "blue" }: { variant?: Variant }) {
  const [left, right] = BLOB_COLORS[variant];

  return (
    <View style={[StyleSheet.absoluteFill, styles.layer]} pointerEvents="none">
      <View style={[styles.blob, styles.blobLeft, { backgroundColor: left }]} />
      <View style={[styles.blob, styles.blobRight, { backgroundColor: right }]} />
    </View>
  );
}

const styles = StyleSheet.create({
  layer: {
    zIndex: 0,
  },
  blob: {
    position: "absolute",
    borderRadius: 999,
    opacity: 0.85,
  },
  blobLeft: {
    width: 220,
    height: 220,
    top: -40,
    left: -60,
  },
  blobRight: {
    width: 200,
    height: 200,
    top: 20,
    right: -50,
  },
});
