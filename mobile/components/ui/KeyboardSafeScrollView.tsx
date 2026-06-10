import {
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  type ScrollViewProps,
  type StyleProp,
  type ViewStyle,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

type Props = ScrollViewProps & {
  children: React.ReactNode;
  style?: StyleProp<ViewStyle>;
  offsetExtra?: number;
};

/**
 * Global keyboard-safe scroll: keeps inputs visible when keyboard opens.
 * Does not change visual design — only layout behavior.
 */
export function KeyboardSafeScrollView({
  children,
  style,
  contentContainerStyle,
  offsetExtra = 0,
  ...rest
}: Props) {
  const insets = useSafeAreaInsets();
  const offset = Platform.OS === "ios" ? insets.top + offsetExtra : 0;

  return (
    <KeyboardAvoidingView
      style={[styles.flex, style]}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
      keyboardVerticalOffset={offset}
    >
      <ScrollView
        {...rest}
        style={styles.flex}
        contentContainerStyle={[styles.content, contentContainerStyle]}
        keyboardShouldPersistTaps="handled"
        keyboardDismissMode="on-drag"
        automaticallyAdjustKeyboardInsets
        showsVerticalScrollIndicator={rest.showsVerticalScrollIndicator ?? false}
      >
        {children}
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  content: { flexGrow: 1 },
});
