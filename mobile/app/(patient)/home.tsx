import { useCallback, useMemo, useState } from "react";
import {
  Pressable,
  RefreshControl,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { router } from "expo-router";
import { SafeAreaView, useSafeAreaInsets } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { LinearGradient } from "expo-linear-gradient";
import { useQueryClient } from "@tanstack/react-query";
import { useMe } from "@/hooks/useMe";
import { useTopDoctors } from "@/hooks/useDoctors";
import { useHomeSearch } from "@/hooks/useHomeSearch";
import { useUnreadNotificationCount } from "@/hooks/useNotifications";
import { getTimeGreeting } from "@/utils/greeting";
import { spacing } from "@/constants/theme";
import { SearchBar } from "@/components/ui/SearchBar";
import { ErrorState } from "@/components/ui/ErrorState";
import { SpecialityGrid } from "@/components/home/SpecialityGrid";
import { TopDoctorsGrid } from "@/components/home/TopDoctorsGrid";
import { HomeSearchResults } from "@/components/home/HomeSearchResults";
import { KeyboardSafeScrollView } from "@/components/ui/KeyboardSafeScrollView";
import { useColors } from "@/hooks/useColors";
import { ScreenLoader } from "@/components/animations/ScreenLoader";
import { useToast } from "@/providers/ToastProvider";
import { useDrawer } from "@/contexts/DrawerContext";
import { useAppTheme } from "@/hooks/useAppTheme";

const QUICK_ACCESS: {
  label: string;
  icon: keyof typeof Ionicons.glyphMap;
  iconColor: string;
  bg: string;
  route?: string;
  tab?: string;
  action?: "emergency";
}[] = [
  { label: "Hospitals", icon: "business", iconColor: "#DC2626", bg: "#E0F2FE", route: "/hospitals" },
  { label: "Doctors", icon: "person", iconColor: "#2563EB", bg: "#E0F2FE", route: "/doctors" },
  { label: "Labs", icon: "flask", iconColor: "#0284C7", bg: "#E0F2FE", route: "/labs" },
  { label: "Blood Banks", icon: "water", iconColor: "#DC2626", bg: "#FEE2E2", route: "/labs", tab: "blood" },
  { label: "Pharmacy", icon: "medkit", iconColor: "#EA580C", bg: "#FFEDD5" },
  { label: "Insurance", icon: "shield-checkmark", iconColor: "#2563EB", bg: "#DBEAFE" },
  { label: "Emergency", icon: "warning", iconColor: "#DC2626", bg: "#FECACA", action: "emergency" },
  { label: "More", icon: "ellipsis-horizontal", iconColor: "#64748B", bg: "#F1F5F9" },
];

export default function PatientHomeScreen() {
  const queryClient = useQueryClient();
  const { showToast } = useToast();
  const { openDrawer } = useDrawer();
  const { theme } = useAppTheme();
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { data: me, isLoading: meLoading, error: meError, refetch: refetchMe } = useMe();
  const {
    data: topDoctors = [],
    isLoading: doctorsLoading,
    error: doctorsError,
    refetch: refetchDoctors,
  } = useTopDoctors();
  const { data: unreadCount = 0, refetch: refetchNotif } = useUnreadNotificationCount();
  const [refreshing, setRefreshing] = useState(false);
  const [search, setSearch] = useState("");
  const { results: searchResults, loading: searchLoading, hasQuery } = useHomeSearch(search);

  const displayName = useMemo(() => {
    const raw = me?.name?.trim() ?? "";
    return raw ? raw.toUpperCase() : "";
  }, [me?.name]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await Promise.all([
      refetchMe(),
      refetchDoctors(),
      refetchNotif(),
      queryClient.invalidateQueries({ queryKey: ["doctors"] }),
      queryClient.invalidateQueries({ queryKey: ["hospitals"] }),
    ]);
    setRefreshing(false);
  }, [refetchMe, refetchDoctors, refetchNotif, queryClient]);

  const openEmergency = useCallback(() => {
    showToast("Opening emergency services…", "info");
    router.push("/emergency");
  }, [showToast]);

  const isLoading = meLoading || doctorsLoading;
  const error = meError ?? doctorsError;
  const badge = unreadCount > 0 ? unreadCount : 0;

  if (isLoading && !me && topDoctors.length === 0) {
    return <ScreenLoader message="Loading home..." />;
  }

  if (error && !me && topDoctors.length === 0) {
    return (
      <SafeAreaView style={[styles.safe, { backgroundColor: theme.background }]}>
        <ErrorState
          message={error instanceof Error ? error.message : "Failed to load"}
          onRetry={() => {
            refetchMe();
            refetchDoctors();
          }}
        />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView
      style={[styles.safe, { backgroundColor: theme.background }]}
      edges={["top"]}
    >
      <KeyboardSafeScrollView
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={colors.primaryTeal}
          />
        }
        contentContainerStyle={{
          flexGrow: 0,
          paddingBottom: insets.bottom + 16,
        }}
      >
        <View style={[styles.header, colors.shadows.card, { backgroundColor: colors.white }]}>
          <Pressable hitSlop={12} onPress={openDrawer}>
            <Ionicons name="menu-outline" size={26} color={colors.textSecondary} />
          </Pressable>
          <View style={styles.logoRow}>
            <Ionicons name="medical" size={22} color={colors.primaryTeal} />
            <Text style={styles.logoText}>MediChain+</Text>
          </View>
          <Pressable
            hitSlop={12}
            style={styles.bellWrap}
            onPress={() => router.push("/(patient)/appointments")}
          >
            <Ionicons name="notifications-outline" size={24} color={colors.textPrimary} />
            {badge > 0 ? (
              <View style={styles.notifBadge}>
                <Text style={styles.notifCount}>{badge > 9 ? "9+" : badge}</Text>
              </View>
            ) : null}
          </Pressable>
        </View>

        <Text style={[styles.greetSmall, { color: colors.textSecondary }]}>
          {getTimeGreeting()}
          {displayName ? `, ${displayName}` : ""} 👋
        </Text>
        <Text style={[styles.greetLarge, { color: colors.textPrimary }]}>Welcome Back!</Text>

        <Pressable
          onPress={() => router.push("/hospitals")}
          style={[styles.heroWrap, colors.shadows.card]}
        >
          <LinearGradient
            colors={["#1E3A8A", "#2563EB", "#38BDF8"]}
            start={{ x: 0, y: 0.5 }}
            end={{ x: 1, y: 0.5 }}
            style={styles.hero}
          >
            <View style={styles.heroText}>
              <Text style={styles.heroTitle}>Get out and about</Text>
              <Text style={styles.heroSub}>Discover trusted care near you</Text>
              <View style={styles.exploreBtn}>
                <Text style={styles.exploreText}>Explore Now →</Text>
              </View>
            </View>
            <View style={styles.heroArt}>
              <Ionicons name="map" size={48} color="rgba(255,255,255,0.25)" />
              <View style={styles.pin}>
                <Ionicons name="location" size={36} color="#fff" />
                <Ionicons
                  name="medical"
                  size={16}
                  color="#2563EB"
                  style={styles.pinCross}
                />
              </View>
            </View>
          </LinearGradient>
        </Pressable>

        <View style={[styles.gridCard, colors.shadows.card, { backgroundColor: colors.white }]}>
          <View style={styles.grid}>
            {QUICK_ACCESS.map((item) => (
              <Pressable
                key={item.label}
                style={styles.gridItem}
                onPress={() => {
                  if (item.action === "emergency") {
                    openEmergency();
                    return;
                  }
                  if (item.route) {
                    if (item.tab) {
                      router.push({ pathname: item.route, params: { tab: item.tab } } as never);
                    } else {
                      router.push(item.route as never);
                    }
                    return;
                  }
                  showToast(`${item.label} coming soon`, "info");
                }}
              >
                <View style={[styles.gridIconBox, { backgroundColor: item.bg }]}>
                  <Ionicons name={item.icon} size={24} color={item.iconColor} />
                </View>
                <Text style={[styles.gridLabel, { color: colors.textSecondary }]}>{item.label}</Text>
              </Pressable>
            ))}
          </View>
        </View>

        <View style={styles.sectionHead}>
          <Text style={[styles.sectionTitle, { color: colors.textPrimary }]}>Specialities</Text>
        </View>

        <SpecialityGrid />

        <SearchBar
          placeholder="Search for services, doctors, hospitals..."
          value={search}
          onChangeText={setSearch}
          leftIcon="search-outline"
        />

        {hasQuery ? (
          <HomeSearchResults
            results={searchResults}
            loading={searchLoading}
            onSelect={() => setSearch("")}
          />
        ) : null}

        <View style={[styles.sectionHead, { marginTop: 16 }]}>
          <Text style={[styles.sectionTitle, { color: colors.textPrimary }]}>Top Doctors to Book</Text>
          <Pressable onPress={() => router.push("/doctors")}>
            <Text style={[styles.viewAll, { color: colors.primaryTeal }]}>View All &gt;</Text>
          </Pressable>
        </View>

        {doctorsLoading ? (
          <View style={[styles.topDoctorsSection, styles.docGridSkeleton]}>
            {[0, 1, 2].map((row) => (
              <View key={row} style={styles.docSkeletonRow}>
                {[1, 2, 3, 4, 5].map((i) => (
                  <View key={`${row}-${i}`} style={styles.docSkeleton}>
                    <View style={[styles.docSkCircle, { backgroundColor: colors.border }]} />
                    <View style={[styles.docSkLine, { backgroundColor: colors.border }]} />
                  </View>
                ))}
              </View>
            ))}
          </View>
        ) : topDoctors.length === 0 ? (
          <Text style={[styles.empty, { color: colors.textSecondary }]}>
            No doctors available from the server.
          </Text>
        ) : (
          <View style={styles.topDoctorsSection}>
            <TopDoctorsGrid doctors={topDoctors} />
          </View>
        )}
      </KeyboardSafeScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  topDoctorsSection: {
    paddingBottom: 16,
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: spacing.screenX,
    paddingVertical: 12,
    marginBottom: 4,
  },
  logoRow: { flexDirection: "row", alignItems: "center", gap: 6 },
  logoText: { fontFamily: "Poppins_700Bold", fontSize: 20, color: "#57D2E8" },
  bellWrap: { position: "relative" },
  notifBadge: {
    position: "absolute",
    top: -4,
    right: -6,
    minWidth: 18,
    height: 18,
    borderRadius: 9,
    backgroundColor: "#EF4444",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 4,
  },
  notifCount: { color: "#fff", fontSize: 10, fontFamily: "Poppins_700Bold" },
  greetSmall: {
    paddingHorizontal: spacing.screenX,
    paddingTop: 12,
    fontFamily: "Poppins_600SemiBold",
    fontSize: 15,
  },
  greetLarge: {
    paddingHorizontal: spacing.screenX,
    fontFamily: "Poppins_700Bold",
    fontSize: 28,
    marginBottom: 16,
  },
  heroWrap: {
    marginHorizontal: spacing.screenX,
    marginBottom: 16,
    borderRadius: 20,
    overflow: "hidden",
  },
  hero: {
    minHeight: 180,
    flexDirection: "row",
    alignItems: "center",
    paddingLeft: 20,
    paddingRight: 12,
    paddingVertical: 20,
  },
  heroText: { flex: 1, paddingRight: 8 },
  heroTitle: { fontFamily: "Poppins_700Bold", fontSize: 20, color: "#fff" },
  heroSub: {
    fontFamily: "Poppins_400Regular",
    fontSize: 13,
    color: "rgba(255,255,255,0.9)",
    marginTop: 6,
    marginBottom: 14,
  },
  exploreBtn: {
    alignSelf: "flex-start",
    borderWidth: 1.5,
    borderColor: "#fff",
    borderRadius: 999,
    paddingHorizontal: 16,
    paddingVertical: 8,
    backgroundColor: "rgba(255,255,255,0.15)",
  },
  exploreText: { fontFamily: "Poppins_600SemiBold", fontSize: 13, color: "#fff" },
  heroArt: {
    width: 100,
    height: 100,
    alignItems: "center",
    justifyContent: "center",
  },
  pin: { position: "absolute", alignItems: "center", justifyContent: "center" },
  pinCross: { position: "absolute", top: 10 },
  gridCard: {
    marginHorizontal: spacing.screenX,
    borderRadius: 20,
    paddingVertical: 16,
    paddingHorizontal: 8,
    marginBottom: 20,
  },
  grid: { flexDirection: "row", flexWrap: "wrap" },
  gridItem: { width: "25%", alignItems: "center", marginBottom: 14 },
  gridIconBox: {
    width: 56,
    height: 56,
    borderRadius: 16,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#fff",
  },
  gridLabel: {
    marginTop: 8,
    fontSize: 11,
    fontFamily: "Poppins_400Regular",
    textAlign: "center",
  },
  sectionHead: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingHorizontal: spacing.screenX,
    marginBottom: 12,
  },
  sectionTitle: {
    fontFamily: "Poppins_700Bold",
    fontSize: 17,
  },
  viewAll: { fontFamily: "Poppins_600SemiBold", fontSize: 14 },
  specScroll: { paddingHorizontal: spacing.screenX, marginBottom: 16 },
  specSkeleton: {
    width: 120,
    height: 38,
    borderRadius: 999,
    backgroundColor: "#E2E8F0",
    marginRight: 10,
  },
  docGridSkeleton: {
    paddingBottom: 16,
    gap: 16,
  },
  docSkeletonRow: {
    flexDirection: "row",
    paddingHorizontal: spacing.screenX,
  },
  docSkeleton: { width: 120, alignItems: "center", marginRight: 12 },
  docSkCircle: {
    width: 72,
    height: 72,
    borderRadius: 36,
  },
  docSkLine: {
    width: 80,
    height: 12,
    borderRadius: 6,
    marginTop: 10,
  },
  empty: {
    textAlign: "center",
    padding: 24,
    fontFamily: "Poppins_400Regular",
  },
});
