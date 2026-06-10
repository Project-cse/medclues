import { StyleSheet, Text, View } from "react-native";
import { BarChart, PieChart } from "react-native-gifted-charts";
import { useLiveData } from "@/src/hooks/useLiveData";
import { getDoctorStats } from "@/src/api/charts";
import { LiveIndicator } from "@/src/components/LiveIndicator";
import { SkeletonCard } from "@/src/components/SkeletonCard";
import { ErrorState } from "@/components/ui/ErrorState";
import { panelColors } from "@/constants/panelTheme";

const CHART_H = 150;
const STATUS_COLORS = ["#FFA726", "#43A047", "#E53935"];

export function DoctorDashboardCharts() {
  const { data, loading, error, refresh, tick } = useLiveData(getDoctorStats, 5000);

  if (loading && !data) {
    return (
      <>
        <SkeletonCard height={120} />
        <SkeletonCard />
        <SkeletonCard />
      </>
    );
  }

  if (error && !data) {
    return <ErrorState message={error} onRetry={refresh} />;
  }

  const donut = (data?.myAppointments?.length
    ? data.myAppointments
    : [{ status: "—", count: 0 }]
  ).map((s, i) => ({
    value: s.count || 0,
    text: s.status,
    color: STATUS_COLORS[i % STATUS_COLORS.length],
  }));

  const earnings = (data?.weeklyEarnings?.length
    ? data.weeklyEarnings
    : [{ day: "—", amount: 0 }]
  ).map((d) => ({ value: d.amount || 0, label: d.day }));

  const queue = data?.queueLength ?? 0;

  return (
    <View style={styles.block}>
      <View style={styles.head}>
        <Text style={styles.title}>Live analytics</Text>
        <LiveIndicator pulseKey={tick} />
      </View>

      <View style={styles.queueCard}>
        <Text style={styles.queueLabel}>Patient queue (today)</Text>
        <Text style={styles.queueValue}>{queue}</Text>
        <Text style={styles.queueHint}>Refreshes every 5 seconds</Text>
      </View>

      <ChartCard title="My appointments by status">
        <PieChart
          data={donut}
          donut
          radius={70}
          innerRadius={42}
          centerLabelComponent={() => (
            <Text style={styles.pieCenter}>Today</Text>
          )}
        />
      </ChartCard>

      <ChartCard title="Earnings this week (INR)">
        <BarChart
          data={earnings}
          barWidth={24}
          height={CHART_H}
          frontColor={panelColors.primary}
          yAxisTextStyle={styles.axis}
          xAxisLabelTextStyle={styles.axis}
        />
      </ChartCard>
    </View>
  );
}

function ChartCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <View style={styles.card}>
      <Text style={styles.cardTitle}>{title}</Text>
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  block: { marginTop: 8 },
  head: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginHorizontal: 16,
    marginBottom: 8,
    alignItems: "center",
  },
  title: { fontFamily: "Poppins_700Bold", fontSize: 16 },
  queueCard: {
    marginHorizontal: 16,
    marginBottom: 12,
    padding: 18,
    borderRadius: 14,
    backgroundColor: panelColors.primary,
  },
  queueLabel: {
    fontFamily: "Poppins_600SemiBold",
    color: "rgba(255,255,255,0.9)",
    fontSize: 13,
  },
  queueValue: {
    fontFamily: "Poppins_700Bold",
    fontSize: 40,
    color: "#fff",
    marginTop: 6,
  },
  queueHint: {
    fontFamily: "Poppins_400Regular",
    fontSize: 11,
    color: "rgba(255,255,255,0.75)",
    marginTop: 4,
  },
  card: {
    marginHorizontal: 16,
    marginBottom: 12,
    padding: 14,
    backgroundColor: panelColors.card,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: panelColors.border,
    alignItems: "center",
  },
  cardTitle: {
    alignSelf: "flex-start",
    fontFamily: "Poppins_600SemiBold",
    fontSize: 13,
    color: panelColors.textSecondary,
    marginBottom: 10,
  },
  axis: { fontSize: 9, color: panelColors.textSecondary },
  pieCenter: { fontFamily: "Poppins_600SemiBold", fontSize: 11 },
});
