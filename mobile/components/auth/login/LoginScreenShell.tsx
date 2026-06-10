import {
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  View,
  type StyleProp,
  type ViewStyle,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { LoginBlobs } from "@/components/auth/login/LoginBlobs";

type Variant = "blue" | "red";

const BG: Record<Variant, string> = {
  blue: "#F0F4FF",
  red: "#FEF2F2",
};

type Props = {
  variant?: Variant;
  children: React.ReactNode;
  contentStyle?: StyleProp<ViewStyle>;
};

/**
 * Keyboard-safe login wrapper.
 * Android: no KeyboardAvoidingView (resize mode handles keyboard).
 * iOS: padding behavior only.
 */
export function LoginScreenShell({ variant = "blue", children, contentStyle }: Props) {
  const scroll = (
    <ScrollView
      style={styles.scroll}
      contentContainerStyle={[styles.scrollContent, contentStyle]}
      keyboardShouldPersistTaps="always"
      keyboardDismissMode="on-drag"
      automaticallyAdjustKeyboardInsets
      showsVerticalScrollIndicator={false}
      bounces
    >
      {children}
    </ScrollView>
  );

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: BG[variant] }]} edges={["top", "bottom"]}>
      <LoginBlobs variant={variant} />
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === "ios" ? "padding" : "padding"}
        keyboardVerticalOffset={Platform.OS === "ios" ? 0 : 0}
      >
        {scroll}
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
  },
  flex: {
    flex: 1,
    zIndex: 1,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    paddingTop: 12,
    paddingBottom: 48,
  },
});
