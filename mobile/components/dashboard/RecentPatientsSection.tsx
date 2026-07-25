import { Text, View } from "react-native";
import { DashboardSection } from "./DashboardSection";
import { EmptyState } from "./EmptyState";
import { ListSkeleton } from "./Skeleton";
import type { PatientRecent } from "@/types/dashboard";

interface RecentPatientsSectionProps {
  patients: PatientRecent[];
  loading?: boolean;
  onViewAll: () => void;
}

export function RecentPatientsSection({
  patients,
  loading,
  onViewAll,
}: RecentPatientsSectionProps) {
  return (
    <DashboardSection title="Recent Patients" onViewAll={onViewAll}>
      {loading ? (
        <ListSkeleton rows={3} />
      ) : patients.length === 0 ? (
        <EmptyState
          icon="people-outline"
          title="No patients yet"
          message="Recent patient visits will show up here."
        />
      ) : (
        <View className="gap-2">
          {patients.map((p) => (
            <View
              key={String(p.id)}
              className="rounded-xl bg-white p-4 shadow-sm"
            >
              <View className="flex-row items-start justify-between">
                <View className="flex-1">
                  <Text className="font-semibold text-slate-900">{p.name}</Text>
                  <Text className="mt-0.5 text-sm text-slate-500">
                    Age {p.age ?? "—"} · Last visit {p.lastVisit ?? "—"}
                  </Text>
                </View>
                {p.condition ? (
                  <View className="rounded-full bg-primary-50 px-2.5 py-1">
                    <Text className="text-xs font-medium text-primary-700">
                      {p.condition}
                    </Text>
                  </View>
                ) : null}
              </View>
            </View>
          ))}
        </View>
      )}
    </DashboardSection>
  );
}
