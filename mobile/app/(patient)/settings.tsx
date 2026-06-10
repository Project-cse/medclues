import { ScrollView, StyleSheet, Switch, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { navigateBackToProfile } from "@/utils/profileNavigation";
import { useAppTheme } from "@/hooks/useAppTheme";

export default function SettingsScreen() {
  const { theme, isDarkMode, toggleTheme } = useAppTheme();

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: theme.background }]} edges={["top"]}>
      <ScreenHeader title="Settings" onBack={navigateBackToProfile} />
      <ScrollView contentContainerStyle={styles.scroll}>
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <View style={styles.row}>
            <View style={styles.rowLeft}>
              <Ionicons
                name={isDarkMode ? "moon" : "sunny"}
                size={22}
                color={theme.primary}
              />
              <Text style={[styles.label, { color: theme.text }]}>Dark Mode</Text>
            </View>
            <Switch
              value={isDarkMode}
              onValueChange={toggleTheme}
              trackColor={{ false: theme.border, true: theme.primary }}
              thumbColor="#FFFFFF"
            />
          </View>
          <Text style={[styles.hint, { color: theme.textSecondary }]}>
            {isDarkMode ? "Dark theme is on across the app." : "Light theme is on."}
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  scroll: { padding: 16 },
  card: {
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
  },
  row: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  rowLeft: { flexDirection: "row", alignItems: "center", gap: 12 },
  label: { fontFamily: "Poppins_600SemiBold", fontSize: 16 },
  hint: {
    marginTop: 12,
    fontFamily: "Poppins_400Regular",
    fontSize: 13,
  },
});
