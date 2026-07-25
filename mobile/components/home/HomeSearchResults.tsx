import { ActivityIndicator, Pressable, StyleSheet, Text, View } from "react-native";
import { router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { spacing } from "@/constants/theme";
import { useColors } from "@/hooks/useColors";
import type { HomeSearchResult } from "@/hooks/useHomeSearch";

type Props = {
  results: HomeSearchResult[];
  loading: boolean;
  onSelect: () => void;
};

function iconFor(type: HomeSearchResult["type"]): keyof typeof Ionicons.glyphMap {
  switch (type) {
    case "service":
      return "grid-outline";
    case "speciality":
      return "heart-outline";
    case "doctor":
      return "person-outline";
    case "hospital":
      return "business-outline";
    case "lab":
      return "flask-outline";
    default:
      return "search-outline";
  }
}

export function HomeSearchResults({ results, loading, onSelect }: Props) {
  const colors = useColors();

  if (loading) {
    return (
      <View style={[styles.box, { backgroundColor: colors.white }]}>
        <ActivityIndicator color={colors.primaryTeal} />
      </View>
    );
  }

  if (results.length === 0) return null;

  const navigate = (item: HomeSearchResult) => {
    onSelect();
    switch (item.type) {
      case "service":
        if (item.route) {
          if (item.tab) {
            router.push({ pathname: item.route, params: { tab: item.tab } } as never);
          } else {
            router.push(item.route as never);
          }
        }
        break;
      case "speciality":
        router.push({ pathname: "/doctors", params: { speciality: item.filterKey } });
        break;
      case "doctor":
        router.push({ pathname: "/doctors/[id]", params: { id: String(item.id) } });
        break;
      case "hospital":
        router.push("/hospitals" as never);
        break;
      case "lab":
        router.push({ pathname: "/labs/[id]", params: { id: String(item.id) } });
        break;
    }
  };

  return (
    <View style={[styles.box, colors.shadows.card, { backgroundColor: colors.white }]}>
      {results.map((item, i) => (
        <Pressable
          key={`${item.type}-${i}`}
          style={[
            styles.row,
            i < results.length - 1 && [styles.rowBorder, { borderBottomColor: colors.border }],
          ]}
          onPress={() => navigate(item)}
        >
          <Ionicons name={iconFor(item.type)} size={18} color={colors.primaryTeal} />
          <View style={styles.textCol}>
            <Text style={[styles.title, { color: colors.textPrimary }]} numberOfLines={1}>
              {item.type === "doctor" || item.type === "hospital" || item.type === "lab"
                ? item.name
                : item.label}
            </Text>
            {item.type === "doctor" ? (
              <Text style={[styles.sub, { color: colors.textSecondary }]} numberOfLines={1}>
                {item.specialization}
              </Text>
            ) : item.type === "hospital" || item.type === "lab" ? (
              <Text style={[styles.sub, { color: colors.textSecondary }]} numberOfLines={1}>
                {item.address}
              </Text>
            ) : (
              <Text style={[styles.sub, { color: colors.textSecondary }]}>{item.type}</Text>
            )}
          </View>
          <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
        </Pressable>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  box: {
    marginHorizontal: spacing.screenX,
    marginTop: 8,
    marginBottom: 8,
    borderRadius: 16,
    paddingVertical: 4,
    overflow: "hidden",
  },
  row: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 10,
  },
  rowBorder: {
    borderBottomWidth: 1,
  },
  textCol: { flex: 1 },
  title: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 14,
  },
  sub: {
    fontFamily: "Poppins_400Regular",
    fontSize: 12,
    marginTop: 2,
    textTransform: "capitalize",
  },
});
