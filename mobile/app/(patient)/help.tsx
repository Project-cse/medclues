import { Linking, Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { navigateBackToProfile } from "@/utils/profileNavigation";
import { useAppTheme } from "@/hooks/useAppTheme";

export default function HelpScreen() {
  const { theme } = useAppTheme();

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: theme.background }]} edges={["top"]}>
      <ScreenHeader title="Help & Support" onBack={navigateBackToProfile} />
      <ScrollView contentContainerStyle={styles.scroll}>
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <Text style={[styles.title, { color: theme.text }]}>Need help?</Text>
          <Text style={[styles.body, { color: theme.textSecondary }]}>
            Contact MediChain+ support for appointments, billing, or technical issues.
          </Text>
          <Pressable
            style={[styles.link, { borderColor: theme.primary }]}
            onPress={() => Linking.openURL("mailto:support@medichain.com")}
          >
            <Text style={[styles.linkText, { color: theme.primary }]}>support@medichain.com</Text>
          </Pressable>
          <Pressable
            style={[styles.link, { borderColor: theme.primary, marginTop: 10 }]}
            onPress={() => Linking.openURL("tel:108")}
          >
            <Text style={[styles.linkText, { color: theme.primary }]}>Emergency: 108</Text>
          </Pressable>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  scroll: { padding: 16 },
  card: { borderRadius: 16, padding: 20, borderWidth: 1 },
  title: { fontFamily: "Poppins_700Bold", fontSize: 18, marginBottom: 8 },
  body: { fontFamily: "Poppins_400Regular", fontSize: 14, lineHeight: 22 },
  link: {
    marginTop: 16,
    borderWidth: 1.5,
    borderRadius: 12,
    paddingVertical: 12,
    alignItems: "center",
  },
  linkText: { fontFamily: "Poppins_600SemiBold", fontSize: 15 },
});
