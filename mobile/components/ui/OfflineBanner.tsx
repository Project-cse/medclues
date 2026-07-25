import { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import NetInfo from "@react-native-community/netinfo";
import { colors } from "@/constants/theme";

type BannerMode = "offline" | "server" | null;

/** Shows device offline OR cannot reach FastAPI (wrong IP / backend stopped) */
export function OfflineBanner({ apiBase }: { apiBase: string }) {
  const [mode, setMode] = useState<BannerMode>(null);

  useEffect(() => {
    let cancelled = false;

    const checkApi = async (): Promise<boolean> => {
      const base = apiBase.replace(/\/$/, "");
      const paths = ["/", "/docs"];
      for (const path of paths) {
        try {
          const ctrl = new AbortController();
          const t = setTimeout(() => ctrl.abort(), 8000);
          const res = await fetch(`${base}${path}`, { method: "GET", signal: ctrl.signal });
          clearTimeout(t);
          if (res.ok || res.status === 404) return true;
        } catch {
          /* try next path */
        }
      }
      return false;
    };

    const update = async (connected: boolean | null) => {
      if (cancelled) return;
      if (connected === false) {
        setMode("offline");
        return;
      }
      const apiOk = await checkApi();
      if (!cancelled) setMode(apiOk ? null : "server");
    };

    NetInfo.fetch().then((s) => update(s.isConnected));
    const unsubNet = NetInfo.addEventListener((s) => {
      update(s.isConnected);
    });

    const interval = setInterval(async () => {
      const s = await NetInfo.fetch();
      if (s.isConnected) {
        const apiOk = await checkApi();
        if (!cancelled) setMode(apiOk ? null : "server");
      } else if (!cancelled) {
        setMode("offline");
      }
    }, 20000);

    return () => {
      cancelled = true;
      unsubNet();
      clearInterval(interval);
    };
  }, [apiBase]);

  if (!mode) return null;

  const isServer = mode === "server";

  return (
    <View style={[styles.banner, isServer && styles.bannerServer]}>
      <Ionicons
        name={isServer ? "server-outline" : "cloud-offline-outline"}
        size={18}
        color="#fff"
      />
      <View style={styles.textWrap}>
        <Text style={styles.text}>
          {isServer ? "Cannot reach API server" : "No internet on device"}
        </Text>
        {isServer ? (
          <Text style={styles.hint} numberOfLines={2}>
            Check mobile/.env → {apiBase} • Backend running? Same Wi‑Fi?
          </Text>
        ) : null}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  banner: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    backgroundColor: colors.red,
    paddingVertical: 8,
    paddingHorizontal: 12,
  },
  bannerServer: {
    backgroundColor: "#B45309",
  },
  textWrap: { flex: 1 },
  text: { color: "#fff", fontWeight: "700", fontSize: 13 },
  hint: { color: "#FEF3C7", fontSize: 11, marginTop: 2 },
});
