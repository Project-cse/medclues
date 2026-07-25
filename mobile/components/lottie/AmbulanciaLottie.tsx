import { Platform, StyleSheet, View, type StyleProp, type ViewStyle } from "react-native";
import LottieView from "lottie-react-native";

const AMBULANCIA_SOURCE = require("@/assets/animations/ambulancia.lottie");

type Props = {
  width?: number;
  height?: number;
  loop?: boolean;
  autoPlay?: boolean;
  style?: StyleProp<ViewStyle>;
  onAnimationFinish?: () => void;
};

export function AmbulanciaLottie({
  width = 250,
  height = 250,
  loop = true,
  autoPlay = true,
  style,
  onAnimationFinish,
}: Props) {
  return (
    <View
      style={[
        styles.wrap,
        { width, height, zIndex: 999, elevation: 999 },
        style,
      ]}
    >
      <LottieView
        source={AMBULANCIA_SOURCE}
        autoPlay={autoPlay}
        loop={loop}
        style={styles.lottie}
        resizeMode="contain"
        renderMode={Platform.OS === "android" ? "HARDWARE" : "AUTOMATIC"}
        onAnimationFinish={onAnimationFinish}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    alignItems: "center",
    justifyContent: "center",
    overflow: "visible",
    backgroundColor: "transparent",
  },
  lottie: {
    width: "100%",
    height: "100%",
    backgroundColor: "transparent",
  },
});
