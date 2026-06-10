import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { appointmentService } from "@/services/appointments";

export const useMyAppointments = (status?: string) =>
  useQuery({
    queryKey: ["appointments", "my", status],
    queryFn: () => appointmentService.getMyAppointments(status),
  });

export const useAvailableSlots = (
  doctorId: string | number | undefined,
  slotDate: string | undefined
) =>
  useQuery({
    queryKey: ["slots", doctorId, slotDate],
    queryFn: () => appointmentService.getAvailableSlots(doctorId!, slotDate!),
    enabled: !!doctorId && !!slotDate,
  });

export const useBookAppointment = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: appointmentService.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["appointments"] });
    },
  });
};
