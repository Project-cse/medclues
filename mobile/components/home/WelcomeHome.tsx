import { Pressable, StyleSheet, Text, View } from "react-native";
import { router } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import Animated, { FadeInDown } from "react-native-reanimated";

function EntryCard({
  title,
  subtitle,
  icon,
  onPress,
  variant = "primary",
  delay,
}: {
  title: string;
  subtitle: string;
  icon: keyof typeof Ionicons.glyphMap;
  onPress: () => void;
  variant?: "primary" | "secondary";
  delay: number;
}) {
  const isPrimary = variant === "primary";

  return (
    <Animated.View entering={FadeInDown.delay(delay).duration(400)}>
      <Pressable
        onPress={onPress}
        style={({ pressed }) => [
          styles.card,
          isPrimary ? styles.cardPrimary : styles.cardSecondary,
          pressed && styles.cardPressed,
        ]}
      >
        <View
          style={[
            styles.cardIcon,
            isPrimary ? styles.cardIconPrimary : styles.cardIconSecondary,
          ]}
        >
          <Ionicons name={icon} size={28} color={isPrimary ? "#fff" : "#2563EB"} />
        </View>
        <View style={styles.cardText}>
          <Text style={[styles.cardTitle, isPrimary && styles.cardTitleLight]}>
            {title}
          </Text>
          <Text style={[styles.cardSubtitle, isPrimary && styles.cardSubtitleLight]}>
            {subtitle}
          </Text>
        </View>
        <Ionicons
          name="chevron-forward"
          size={22}
          color={isPrimary ? "#fff" : "#94a3b8"}
        />
      </Pressable>
    </Animated.View>
  );
}

function WelcomeContent() {
  return (
    <SafeAreaView style={styles.safe}>
      <LinearGradient
        colors={["#eff6ff", "#f8fafc", "#ffffff"]}
        style={StyleSheet.absoluteFill}
      />

      {/* Decorative blobs */}
      <View style={[styles.blob, styles.blobTop]} />
      <View style={[styles.blob, styles.blobRight]} />

      <View style={styles.body}>
        <Animated.View entering={FadeInDown.duration(500).springify()}>
          <View style={styles.headerRow}>
            <Animated.View
              entering={FadeInDown.delay(80).springify()}
              style={styles.logoSmall}
            >
              <Ionicons name="medical" size={28} color="#fff" />
            </Animated.View>
            <View style={styles.headerText}>
              <Text style={styles.welcomeLabel}>Welcome to</Text>
              <Text style={styles.brandTitle}>MediChain+</Text>
            </View>
          </View>
          <Text style={styles.heroText}>
            Book care, manage patients, and run your hospital — all in one place.
          </Text>
        </Animated.View>

        <Animated.Text
          entering={FadeInDown.delay(200).duration(400)}
          style={styles.sectionLabel}
        >
          GET STARTED
        </Animated.Text>

        <View style={styles.cards}>
          <EntryCard
            delay={320}
            title="I'm a Patient"
            subtitle="Book appointments, view records & your care plan"
            icon="heart-outline"
            variant="primary"
            onPress={() => router.push("/(auth)/login-patient")}
          />
          <EntryCard
            delay={420}
            title="Hospital Staff"
            subtitle="Doctor, admin, or dean — open your PMS dashboard"
            icon="briefcase-outline"
            variant="secondary"
            onPress={() => router.push("/(auth)/login-staff" as import("expo-router").Href)}
          />
        </View>

        <Animated.View
          entering={FadeInDown.delay(520).duration(450)}
          style={styles.footerNote}
        >
          <Ionicons name="shield-checkmark-outline" size={18} color="#2563EB" />
          <Text style={styles.footerText}>
            Secure sign-in for patients and hospital staff on your FastAPI backend.
          </Text>
        </Animated.View>
      </View>
    </SafeAreaView>
  );
}

export function WelcomeHome() {
  return <WelcomeContent />;
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: "#f8fafc",
  },
  blob: {
    position: "absolute",
    borderRadius: 999,
    backgroundColor: "rgba(37, 99, 235, 0.08)",
  },
  blobTop: {
    width: 220,
    height: 220,
    top: -80,
    right: -60,
  },
  blobRight: {
    width: 140,
    height: 140,
    bottom: 120,
    left: -40,
  },
  body: {
    flex: 1,
    paddingHorizontal: 24,
    paddingTop: 16,
    paddingBottom: 28,
  },
  headerRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
    marginBottom: 12,
  },
  logoSmall: {
    width: 56,
    height: 56,
    borderRadius: 18,
    backgroundColor: "#2563EB",
    alignItems: "center",
    justifyContent: "center",
    shadowColor: "#2563EB",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.35,
    shadowRadius: 12,
    elevation: 8,
  },
  headerText: {
    flex: 1,
  },
  welcomeLabel: {
    fontSize: 14,
    color: "#64748b",
    fontWeight: "500",
  },
  brandTitle: {
    fontSize: 28,
    fontWeight: "800",
    color: "#0f172a",
    letterSpacing: -0.5,
  },
  heroText: {
    fontSize: 16,
    lineHeight: 24,
    color: "#64748b",
    marginBottom: 28,
  },
  sectionLabel: {
    fontSize: 12,
    fontWeight: "700",
    letterSpacing: 1.2,
    color: "#94a3b8",
    marginBottom: 14,
  },
  cards: {
    gap: 14,
  },
  card: {
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
    padding: 18,
    borderRadius: 20,
  },
  cardPrimary: {
    backgroundColor: "#2563EB",
    shadowColor: "#2563EB",
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.35,
    shadowRadius: 16,
    elevation: 10,
  },
  cardSecondary: {
    backgroundColor: "#fff",
    borderWidth: 1,
    borderColor: "#e2e8f0",
    shadowColor: "#0f172a",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.06,
    shadowRadius: 12,
    elevation: 3,
  },
  cardPressed: {
    opacity: 0.92,
    transform: [{ scale: 0.98 }],
  },
  cardIcon: {
    width: 52,
    height: 52,
    borderRadius: 16,
    alignItems: "center",
    justifyContent: "center",
  },
  cardIconPrimary: {
    backgroundColor: "rgba(255,255,255,0.2)",
  },
  cardIconSecondary: {
    backgroundColor: "#eff6ff",
  },
  cardText: {
    flex: 1,
  },
  cardTitle: {
    fontSize: 17,
    fontWeight: "700",
    color: "#0f172a",
  },
  cardTitleLight: {
    color: "#fff",
  },
  cardSubtitle: {
    marginTop: 4,
    fontSize: 13,
    lineHeight: 18,
    color: "#64748b",
  },
  cardSubtitleLight: {
    color: "#bfdbfe",
  },
  footerNote: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 10,
    marginTop: 28,
    padding: 16,
    borderRadius: 16,
    backgroundColor: "rgba(37, 99, 235, 0.08)",
  },
  footerText: {
    flex: 1,
    fontSize: 13,
    lineHeight: 20,
    color: "#475569",
  },
});
