import { ScrollView, StyleSheet, useWindowDimensions, View } from "react-native";
import { router } from "expo-router";
import { TopDoctorCard, TOP_DOCTOR_CARD_WIDTH } from "@/components/home/TopDoctorCard";
import { spacing } from "@/constants/theme";
import type { Doctor } from "@/types/domain";

const CARDS_PER_ROW = 5;
const CARD_GAP = 12;
const ROW_GAP = 16;

type Props = {
  doctors: Doctor[];
};

function chunkRows(doctors: Doctor[], size: number): Doctor[][] {
  const rows: Doctor[][] = [];
  for (let i = 0; i < doctors.length; i += size) {
    rows.push(doctors.slice(i, i + size));
  }
  return rows;
}

function rowContentWidth(cardCount: number): number {
  if (cardCount <= 0) return 0;
  return cardCount * TOP_DOCTOR_CARD_WIDTH + (cardCount - 1) * CARD_GAP;
}

function fitsFiveCardsOnScreen(screenWidth: number): boolean {
  const inner = screenWidth - spacing.screenX * 2;
  return inner >= rowContentWidth(CARDS_PER_ROW);
}

type CardWrapProps = {
  doctor: Doctor;
  gapAfter: boolean;
};

function DoctorCardWrap({ doctor, gapAfter }: CardWrapProps) {
  return (
    <View style={gapAfter ? styles.cardGap : undefined}>
      <TopDoctorCard
        doctor={doctor}
        onPress={() =>
          router.push({ pathname: "/doctors/[id]", params: { id: String(doctor.id) } })
        }
      />
    </View>
  );
}

/**
 * Up to 5 full-size cards per row, packed left with equal gaps.
 * Narrow screens: each row scrolls horizontally (no space-between gaps).
 * Wide screens: flexWrap grid without row scroll.
 */
export function TopDoctorsGrid({ doctors }: Props) {
  const { width } = useWindowDimensions();

  if (fitsFiveCardsOnScreen(width)) {
    return (
      <View style={[styles.flexGrid, { paddingHorizontal: spacing.screenX }]}>
        {doctors.map((doctor) => (
          <View key={String(doctor.id)} style={styles.gridCell}>
            <DoctorCardWrap doctor={doctor} gapAfter={false} />
          </View>
        ))}
      </View>
    );
  }

  const rows = chunkRows(doctors, CARDS_PER_ROW);

  return (
    <View style={styles.wrap}>
      {rows.map((row, rowIndex) => (
        <ScrollView
          key={rowIndex}
          horizontal
          nestedScrollEnabled
          showsHorizontalScrollIndicator={false}
          style={[styles.row, rowIndex > 0 && styles.rowScroll]}
          contentContainerStyle={[
            styles.rowContent,
            { paddingHorizontal: spacing.screenX },
          ]}
        >
          {row.map((doc, index) => (
            <DoctorCardWrap
              key={String(doc.id)}
              doctor={doc}
              gapAfter={index < row.length - 1}
            />
          ))}
        </ScrollView>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {},
  flexGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    justifyContent: "flex-start",
    alignItems: "flex-start",
    columnGap: CARD_GAP,
    rowGap: ROW_GAP,
  },
  rowScroll: {
    marginTop: ROW_GAP,
    flexGrow: 0,
  },
  row: {
    flexGrow: 0,
  },
  rowContent: {
    flexDirection: "row",
    alignItems: "flex-start",
    justifyContent: "flex-start",
    flexGrow: 0,
  },
  cardGap: {
    marginRight: CARD_GAP,
  },
  gridCell: {
    width: TOP_DOCTOR_CARD_WIDTH,
  },
});
