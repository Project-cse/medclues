import { FlatList, Text, View } from "react-native";
import { PageHeader } from "@/components/PageHeader";
import { Screen } from "@/components/Screen";
import { Loading } from "@/components/Loading";
import { useAppointments } from "@/hooks/useAppointments";
import type { Appointment } from "@/types/api";

export default function AppointmentsScreen() {
  const { data: appointments = [], isLoading, isError, error } = useAppointments();

  if (isLoading) {
    return <Loading message="Loading appointments..." />;
  }

  return (
    <Screen scroll={false} className="px-0">
      <View className="px-4">
        <PageHeader title="Appointments" subtitle="getAllAppointments()" />
      </View>

      {isError ? (
        <View className="mx-4 rounded-2xl bg-red-50 p-4">
          <Text className="text-red-700">
            {error instanceof Error ? error.message : "Failed to load"}
          </Text>
        </View>
      ) : (
        <FlatList<Appointment>
          className="flex-1 px-4"
          data={appointments}
          keyExtractor={(item, index) => String(item.id ?? index)}
          contentContainerClassName="pb-8"
          ListEmptyComponent={
            <View className="rounded-2xl bg-white p-6">
              <Text className="text-center text-slate-500">No appointments found.</Text>
            </View>
          }
          renderItem={({ item }) => (
            <View className="mb-3 rounded-2xl bg-white p-4 shadow-sm">
              <Text className="text-base font-semibold text-slate-900">
                {item.patientName ?? item.userData?.name ?? "Unknown patient"}
              </Text>
              <Text className="mt-1 text-slate-500">
                {item.slotDate} · {item.slotTime}
              </Text>
              <Text className="mt-2 text-sm font-medium capitalize text-primary-700">
                {item.status ?? "pending"}
              </Text>
            </View>
          )}
        />
      )}
    </Screen>
  );
}
