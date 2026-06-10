import { StyleSheet, Text, View } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";

type Variant = "blue" | "red";

const CONFIG = {
  blue: {
    gradient: ["#2563EB", "#0EA5E9"] as [string, string],
    accentIcon: "heart" as const,
    brandColor: "#1E3A5F",
    plusColor: "#2563EB",
    lineColor: "#0EA5E9",
    subtitle: "Patient Management System",
    welcomeTitle: "Welcome Back!",
    welcomeSub: "Sign in to continue to your account",
  },
  red: {
    gradient: ["#B91C1C", "#EF4444"] as [string, string],
    accentIcon: "shield" as const,
    brandColor: "#7F1D1D",
    plusColor: "#B91C1C",
    lineColor: "#B91C1C",
    subtitle: "Hospital Administration",
    welcomeTitle: "Staff Sign In",
    welcomeSub: "Sign in to your admin account",
  },
};

export function BrandLogoMark({ variant = "blue" }: { variant?: Variant }) {
  const c = CONFIG[variant];

  return (
    <View>
      <LinearGradient
        colors={c.gradient}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.logoBox}
      >
        <Text style={styles.plus}>+</Text>
        <View style={styles.accentWrap}>
          <Ionicons name={c.accentIcon} size={12} color="#fff" />
        </View>
      </LinearGradient>
    </View>
  );
}

export function BrandHeaderText({ variant = "blue" }: { variant?: Variant }) {
  const c = CONFIG[variant];

  return (
    <>
      <View>
        <Text style={[styles.brandName, { color: c.brandColor }]}>
          MediChain<Text style={[styles.brandPlus, { color: c.plusColor }]}>+</Text>
        </Text>
        <Text style={styles.brandSub}>{c.subtitle}</Text>
      </View>
      <View style={styles.welcomeWrap}>
        <View style={[styles.accentLine, { backgroundColor: c.lineColor }]} />
        <Text style={styles.welcomeTitle}>{c.welcomeTitle}</Text>
        <Text style={styles.welcomeSub}>{c.welcomeSub}</Text>
      </View>
    </>
  );
}

const styles = StyleSheet.create({
  logoBox: {
    width: 64,
    height: 64,
    borderRadius: 16,
    alignItems: "center",
    justifyContent: "center",
    alignSelf: "center",
  },
  plus: {
    fontSize: 28,
    fontFamily: "Poppins_700Bold",
    color: "#fff",
    lineHeight: 32,
  },
  accentWrap: {
    position: "absolute",
    right: 10,
    bottom: 10,
  },
  brandName: {
    marginTop: 14,
    textAlign: "center",
    fontSize: 30,
    fontFamily: "Poppins_700Bold",
  },
  brandPlus: {
    fontFamily: "Poppins_700Bold",
  },
  brandSub: {
    textAlign: "center",
    fontSize: 14,
    fontFamily: "Poppins_400Regular",
    color: "#9CA3AF",
    marginTop: 4,
  },
  welcomeWrap: {
    alignItems: "center",
    marginTop: 12,
    marginBottom: 4,
  },
  accentLine: {
    width: 32,
    height: 2,
    borderRadius: 1,
    marginBottom: 12,
  },
  welcomeTitle: {
    fontSize: 20,
    fontFamily: "Poppins_700Bold",
    color: "#111827",
  },
  welcomeSub: {
    fontSize: 14,
    fontFamily: "Poppins_400Regular",
    color: "#6B7280",
    marginTop: 4,
  },
});
