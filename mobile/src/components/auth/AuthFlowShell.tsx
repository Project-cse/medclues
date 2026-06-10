import { useEffect, useRef } from "react";
import {
  Animated,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { router } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import { getAuthTheme, type AuthThemeKey } from "@/src/utils/authTheme";
import { colors } from "@/constants/theme";

type Props = {
  theme: AuthThemeKey;
  title: string;
  subtitle: string;
  icon: keyof typeof Ionicons.glyphMap;
  children: React.ReactNode;
  footer?: React.ReactNode;
};

export function AuthFlowShell({ theme, title, subtitle, icon, children, footer }: Props) {
  const t = getAuthTheme(theme);
  const bounce = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.sequence([
      Animated.timing(bounce, { toValue: -8, duration: 280, useNativeDriver: true }),
      Animated.timing(bounce, { toValue: 0, duration: 280, useNativeDriver: true }),
      Animated.timing(bounce, { toValue: -4, duration: 200, useNativeDriver: true }),
      Animated.timing(bounce, { toValue: 0, duration: 200, useNativeDriver: true }),
    ]).start();
  }, [bounce]);

  return (
    <SafeAreaView style={styles.safe}>
      <LinearGradient colors={t.gradient} style={styles.headerBand} />
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === "ios" ? "padding" : "height"}
      >
        <ScrollView
          contentContainerStyle={styles.scroll}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          <Pressable style={styles.back} onPress={() => router.back()} hitSlop={12}>
            <Ionicons name="arrow-back" size={24} color="#fff" />
          </Pressable>

          <Animated.View style={[styles.iconWrap, { transform: [{ translateY: bounce }] }]}>
            <Ionicons name={icon} size={36} color={t.primary} />
          </Animated.View>
          <Text style={styles.headerTitle}>{title}</Text>
          <Text style={styles.headerSub}>{subtitle}</Text>

          <View style={styles.card}>{children}</View>
          {footer}
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  flex: { flex: 1 },
  headerBand: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    height: 220,
    borderBottomLeftRadius: 32,
    borderBottomRightRadius: 32,
  },
  scroll: { paddingHorizontal: 22, paddingBottom: 32, paddingTop: 8 },
  back: { alignSelf: "flex-start", marginTop: 4, marginBottom: 12 },
  iconWrap: {
    alignSelf: "center",
    width: 72,
    height: 72,
    borderRadius: 20,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 12,
    shadowColor: "#000",
    shadowOpacity: 0.12,
    shadowRadius: 12,
    elevation: 6,
  },
  headerTitle: {
    fontFamily: "Poppins_700Bold",
    fontSize: 24,
    color: "#fff",
    textAlign: "center",
  },
  headerSub: {
    fontFamily: "Poppins_400Regular",
    fontSize: 14,
    color: "rgba(255,255,255,0.9)",
    textAlign: "center",
    marginTop: 8,
    marginBottom: 20,
    paddingHorizontal: 8,
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: 20,
    padding: 22,
    borderWidth: 1,
    borderColor: colors.border,
  },
});
