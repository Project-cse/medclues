import { Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { HOME_SPECIALITIES } from "@/constants/homeSpecialities";
import { spacing } from "@/constants/theme";
import { useColors } from "@/hooks/useColors";

const COLS = 6;
const CIRCLE = 50;

/** 2 rows — solid cyan circles with white icons (screenshot style). */
export function SpecialityGrid() {
  const colors = useColors();
  const rows = [HOME_SPECIALITIES.slice(0, COLS), HOME_SPECIALITIES.slice(COLS, COLS * 2)];

  return (
    <View style={styles.wrap}>
      {rows.map((row, rowIndex) => (
        <View key={rowIndex} style={styles.row}>
          {row.map((item) => (
            <Pressable
              key={item.name}
              style={styles.item}
              onPress={() =>
                router.push({
                  pathname: "/doctors",
                  params: { speciality: item.filterKey },
                })
              }
            >
              <View style={[styles.circle, { backgroundColor: colors.specCircleFill }]}>
                <Ionicons name={item.icon} size={22} color="#FFFFFF" />
              </View>
              <Text
                style={[styles.label, { color: colors.textPrimary }]}
                numberOfLines={2}
                adjustsFontSizeToFit
                minimumFontScale={0.72}
              >
                {item.name}
              </Text>
            </Pressable>
          ))}
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    paddingHorizontal: spacing.screenX,
    marginBottom: 16,
    gap: 14,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
  },
  item: {
    flex: 1,
    alignItems: "center",
    maxWidth: 58,
  },
  circle: {
    width: CIRCLE,
    height: CIRCLE,
    borderRadius: CIRCLE / 2,
    alignItems: "center",
    justifyContent: "center",
  },
  label: {
    marginTop: 6,
    fontFamily: "Poppins_400Regular",
    fontSize: 9,
    textAlign: "center",
    lineHeight: 12,
    width: CIRCLE + 6,
  },
});
