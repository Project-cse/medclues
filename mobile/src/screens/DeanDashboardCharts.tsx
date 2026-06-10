import { StyleSheet, Text, View } from "react-native";
import { BarChart, LineChart, PieChart } from "react-native-gifted-charts";
import { useLiveData } from "@/src/hooks/useLiveData";
import { getDeanStats } from "@/src/api/charts";
import { LiveIndicator } from "@/src/components/LiveIndicator";
import { SkeletonCard } from "@/src/components/SkeletonCard";
import { ErrorState } from "@/components/ui/ErrorState";
import { panelColors } from "@/constants/panelTheme";

const CHART_H = 160;
const PIE_COLORS = ["#1565C0", "#FFA726", "#94A3B8"];

export function DeanDashboardCharts() {
  const { data, loading, error, refresh, tick } = useLiveData(getDeanStats, 5000);

  if (loading && !data) {
    return (
      <>
        <SkeletonCard />
        <SkeletonCard />
        <SkeletonCard />
      </>
    );
  }

  if (error && !data) {
    return <ErrorState message={error} onRetry={refresh} />;
  }

  const dept = (data?.deptLoad?.length ? data.deptLoad : [{ dept: "—", count: 0 }]).map(
    (d) => ({ value: d.count || 0, label: d.dept?.slice(0, 8) ?? "—" })
  );

  const pie = (data?.doctorAvailability?.length
    ? data.doctorAvailability
    : [{ status: "N/A", count: 1 }]
  ).map((s, i) => ({
    value: s.count || 0,
    text: s.status,
    color: PIE_COLORS[i % PIE_COLORS.length],
  }));

  const revenue = (data?.weeklyRevenue?.length
    ? data.weeklyRevenue
    : [{ day: "—", amount: 0 }]
  ).map((d) => ({ value: d.amount || 0, label: d.day }));

  return (
    <View style={styles.block}>
      <View style={styles.head}>
        <Text style={styles.title}>Live analytics</Text>
        <LiveIndicator pulseKey={tick} />
      </View>

      <ChartCard title="Appointments per department">
        <BarChart data={dept} barWidth={22} height={CHART_H} frontColor={panelColors.primary} />
      </ChartCard>

      <ChartCard title="Doctor availability">
        <PieChart
          data={pie}
          donut
          radius={72}
          innerRadius={44}
          centerLabelComponent={() => (
            <Text style={styles.pieCenter}>Staff</Text>
          )}
        />
      </ChartCard>

      <ChartCard title="Weekly revenue (INR)">
        <LineChart
          data={revenue}
          height={CHART_H}
          color={panelColors.completed}
          curved
          thickness={2}
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
  pieCenter: { fontFamily: "Poppins_600SemiBold", fontSize: 12, color: panelColors.textPrimary },
});
