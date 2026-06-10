import { StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/constants/theme";

interface StarRatingProps {
  rating?: number;
  reviews?: number;
  size?: number;
  showCount?: boolean;
}

export function StarRating({
  rating,
  reviews,
  size = 14,
  showCount = true,
}: StarRatingProps) {
  if (rating == null || rating <= 0) return null;

  const full = Math.floor(rating);
  const stars = [0, 1, 2, 3, 4].map((i) => (
    <Ionicons
      key={i}
      name={i < full ? "star" : i < rating ? "star-half" : "star-outline"}
      size={size}
      color={colors.star}
    />
  ));

  return (
    <View style={styles.row}>
      <View style={styles.stars}>{stars}</View>
      {showCount ? (
        <>
          <Text style={styles.rating}>{rating.toFixed(1)}</Text>
          {reviews != null && reviews > 0 ? (
            <Text style={styles.reviews}>({reviews} reviews)</Text>
          ) : null}
        </>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", alignItems: "center", flexWrap: "wrap", gap: 4 },
  stars: { flexDirection: "row" },
  rating: { fontSize: 13, fontWeight: "700", color: colors.textPrimary },
  reviews: { fontSize: 12, color: colors.textSecondary },
});
