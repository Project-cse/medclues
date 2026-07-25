import { StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { AmbulanciaLottie } from "@/components/lottie/AmbulanciaLottie";

type Props = {
  message?: string;
  subMessage?: string;
};

/** Full-screen loader — ambulancia visible (no Modal overlay). */
export function ScreenLoader({
  message = "Loading...",
  subMessage = "Please wait...",
}: Props) {
  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.center}>
        <AmbulanciaLottie width={200} height={200} loop autoPlay />
        <Text style={styles.message}>{message}</Text>
        <Text style={styles.sub}>{subMessage}</Text>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: "#FFFFFF",
  },
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
  },
  message: {
    marginTop: 16,
    fontFamily: "Poppins_600SemiBold",
    fontSize: 16,
    color: "#0EA5E9",
    textAlign: "center",
  },
  sub: {
    marginTop: 4,
    fontFamily: "Poppins_400Regular",
    fontSize: 13,
    color: "#94A3B8",
    textAlign: "center",
  },
});
