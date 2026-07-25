import { ScrollView, StyleSheet, Text, View } from "react-native";
import { BarChart, LineChart } from "react-native-gifted-charts";
import { useLiveData } from "@/src/hooks/useLiveData";
import { getAdminStats } from "@/src/api/charts";
import { LiveIndicator } from "@/src/components/LiveIndicator";
import { SkeletonCard } from "@/src/components/SkeletonCard";
import { ErrorState } from "@/components/ui/ErrorState";
import { panelColors } from "@/constants/panelTheme";

const CHART_H = 160;
const EMPTY_LINE = [{ value: 0, label: "—" }];
const EMPTY_BAR = [{ value: 0, label: "—" }];

export function AdminDashboardCharts() {
  const { data, loading, error, refresh, tick } = useLiveData(getAdminStats, 5000);

  if (loading && !data) {
    return (
      <>
        <SkeletonCard height={200} />
        <SkeletonCard height={200} />
        <SkeletonCard height={200} />
      </>
    );
  }

  if (error && !data) {
    return <ErrorState message={error} onRetry={refresh} />;
  }

  const payments = data?.paymentsToday?.length
    ? data.paymentsToday.map((p) => ({ value: p.amount || 0, label: p.hour }))
    : EMPTY_LINE;

  const users = data?.usersByRole?.length
    ? data.usersByRole.map((u) => ({ value: u.count || 0, label: u.role }))
    : EMPTY_BAR;

  const appts = data?.appointmentsPerHour?.length
    ? data.appointmentsPerHour.map((a) => ({ value: a.count || 0, label: a.hour }))
    : EMPTY_LINE;

  const maxPay = Math.max(...payments.map((p) => p.value), 1);

  return (
    <View style={styles.block}>
      <View style={styles.head}>
        <Text style={styles.title}>Live analytics</Text>
        <LiveIndicator pulseKey={tick} />
      </View>

      <ChartCard title="Payments today (INR)">
        <LineChart
          data={payments}
          height={CHART_H}
          color={panelColors.primary}
          thickness={2}
          curved
          maxValue={maxPay * 1.2 || 100}
          yAxisTextStyle={styles.axis}
          xAxisLabelTextStyle={styles.axis}
          noOfSections={4}
          areaChart
          startFillColor="rgba(21,101,192,0.35)"
          endFillColor="rgba(21,101,192,0.05)"
        />
      </ChartCard>

      <ChartCard title="Users by role">
        <BarChart
          data={users}
          barWidth={28}
          height={CHART_H}
          frontColor={panelColors.primary}
          yAxisTextStyle={styles.axis}
          xAxisLabelTextStyle={styles.axis}
          noOfSections={4}
        />
      </ChartCard>

      <ChartCard title="Appointments per hour">
        <LineChart
          data={appts}
          height={CHART_H}
          color="#42A5F5"
          thickness={2}
          areaChart
          startFillColor="rgba(66,165,245,0.3)"
          endFillColor="rgba(66,165,245,0.05)"
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
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        {children}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  block: { marginTop: 8 },
  head: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginHorizontal: 16,
    marginBottom: 8,
  },
  title: { fontFamily: "Poppins_700Bold", fontSize: 16, color: panelColors.textPrimary },
  card: {
    marginHorizontal: 16,
    marginBottom: 12,
    padding: 14,
    backgroundColor: panelColors.card,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: panelColors.border,
  },
  cardTitle: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 13,
    color: panelColors.textSecondary,
    marginBottom: 10,
  },
  axis: { fontSize: 9, color: panelColors.textSecondary },
});
