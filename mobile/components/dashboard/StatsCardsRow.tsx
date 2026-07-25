import { ScrollView, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import type { DashboardStatItem, DashboardStatsCards } from "@/types/dashboard";
import { StatsSkeleton } from "./Skeleton";

function buildStatItems(stats: DashboardStatsCards): DashboardStatItem[] {
  return [
    {
      key: "patients",
      label: "Patients Today",
      value: stats.patientsToday,
      icon: "people",
      bgClass: "bg-blue-50",
      iconColor: "#2563EB",
    },
    {
      key: "appointments",
      label: "Appointments",
      value: stats.appointmentsToday,
      icon: "calendar",
      bgClass: "bg-violet-50",
      iconColor: "#7c3aed",
    },
    {
      key: "billing",
      label: "Pending Billing",
      value: stats.pendingBilling,
      icon: "wallet",
      bgClass: "bg-amber-50",
      iconColor: "#d97706",
    },
    {
      key: "registrations",
      label: "New Registrations",
      value: stats.newRegistrations,
      icon: "person-add",
      bgClass: "bg-emerald-50",
      iconColor: "#059669",
    },
  ];
}

interface StatsCardsRowProps {
  stats?: DashboardStatsCards;
  loading?: boolean;
  hiddenKeys?: string[];
}

export function StatsCardsRow({
  stats,
  loading,
  hiddenKeys = [],
}: StatsCardsRowProps) {
  if (loading || !stats) {
    return <StatsSkeleton />;
  }

  const items = buildStatItems(stats).filter((i) => !hiddenKeys.includes(i.key));

  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerClassName="gap-3 px-4 pb-1"
    >
      {items.map((item) => (
        <View
          key={item.key}
          className={`w-36 rounded-2xl p-4 ${item.bgClass}`}
        >
          <View className="mb-3 h-10 w-10 items-center justify-center rounded-xl bg-white/80">
            <Ionicons
              name={item.icon as keyof typeof Ionicons.glyphMap}
              size={22}
              color={item.iconColor}
            />
          </View>
          <Text className="text-2xl font-bold text-slate-900">{item.value}</Text>
          <Text className="mt-1 text-xs font-medium text-slate-600">
            {item.label}
          </Text>
        </View>
      ))}
    </ScrollView>
  );
}
