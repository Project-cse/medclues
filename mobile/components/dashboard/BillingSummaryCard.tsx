import { Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { DashboardSection } from "./DashboardSection";
import { CardSkeleton } from "./Skeleton";
import type { BillingSummary } from "@/types/api";

interface BillingSummaryCardProps {
  billing?: BillingSummary & { pendingAmount?: number };
  loading?: boolean;
}

export function BillingSummaryCard({ billing, loading }: BillingSummaryCardProps) {
  return (
    <DashboardSection title="Billing Summary">
      {loading || !billing ? (
        <CardSkeleton />
      ) : (
        <View className="rounded-2xl bg-primary-600 p-5">
          <View className="mb-4 flex-row items-center gap-2">
            <Ionicons name="cash-outline" size={22} color="#fff" />
            <Text className="text-lg font-bold text-white">Today&apos;s Collection</Text>
          </View>

          <Text className="text-3xl font-bold text-white">
            ₹{Math.round(billing.revenueToday).toLocaleString("en-IN")}
          </Text>

          <View className="mt-4 flex-row gap-4 border-t border-white/20 pt-4">
            <View className="flex-1">
              <Text className="text-xs text-blue-100">Pending amount</Text>
              <Text className="mt-0.5 text-lg font-semibold text-white">
                ₹{Math.round(billing.pendingAmount ?? 0).toLocaleString("en-IN")}
              </Text>
            </View>
            <View className="flex-1">
              <Text className="text-xs text-blue-100">Paid today</Text>
              <Text className="mt-0.5 text-lg font-semibold text-white">
                {billing.paidAppointments ?? 0} visits
              </Text>
            </View>
          </View>
        </View>
      )}
    </DashboardSection>
  );
}
