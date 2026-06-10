import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { registerApiToast } from "@/src/utils/toastBridge";
import { Pressable, StyleSheet, Text, View } from "react-native";
import Animated, { FadeInUp, FadeOutUp } from "react-native-reanimated";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/constants/theme";

type ToastType = "success" | "error" | "info";

interface ToastState {
  message: string;
  type: ToastType;
}

interface ToastContextValue {
  showToast: (message: string, type?: ToastType) => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

export function ToastProvider({ children }: { children: ReactNode }) {
  const insets = useSafeAreaInsets();
  const [toast, setToast] = useState<ToastState | null>(null);

  const showToast = useCallback((message: string, type: ToastType = "info") => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3200);
  }, []);

  useEffect(() => {
    registerApiToast(showToast);
  }, [showToast]);

  const value = useMemo(() => ({ showToast }), [showToast]);

  const icon =
    toast?.type === "success"
      ? "checkmark-circle"
      : toast?.type === "error"
        ? "alert-circle"
        : "information-circle";

  const bg =
    toast?.type === "success"
      ? colors.green
      : toast?.type === "error"
        ? colors.red
        : colors.primaryBlue;

  return (
    <ToastContext.Provider value={value}>
      {children}
      {toast ? (
        <Animated.View
          entering={FadeInUp.duration(220)}
          exiting={FadeOutUp.duration(180)}
          style={[styles.wrap, { top: insets.top + 8 }]}
        >
          <Pressable style={[styles.toast, { backgroundColor: bg }]} onPress={() => setToast(null)}>
            <Ionicons name={icon} size={22} color="#fff" />
            <Text style={styles.text}>{toast.message}</Text>
          </Pressable>
        </Animated.View>
      ) : null}
    </ToastContext.Provider>
  );
}

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error("useToast must be used within ToastProvider");
  return ctx;
}

const styles = StyleSheet.create({
  wrap: {
    position: "absolute",
    left: 16,
    right: 16,
    zIndex: 9999,
  },
  toast: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    paddingVertical: 14,
    paddingHorizontal: 16,
    borderRadius: 14,
    ...{ shadowColor: "#000", shadowOpacity: 0.15, shadowRadius: 8, elevation: 6 },
  },
  text: { flex: 1, color: "#fff", fontSize: 14, fontWeight: "600" },
});
