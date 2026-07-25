import { useQuery } from "@tanstack/react-query";
import { doctorService } from "@/services/doctors";

export const useDoctors = (params?: {
  search?: string;
  speciality?: string;
  hospitalId?: number;
}) =>
  useQuery({
    queryKey: ["doctors", params],
    queryFn: () => doctorService.getAll(params),
  });

export const useDoctor = (id: string | number | undefined) =>
  useQuery({
    queryKey: ["doctor", id],
    queryFn: () => doctorService.getById(id!),
    enabled: id != null && id !== "",
  });

export const useTopDoctors = () =>
  useQuery({
    queryKey: ["doctors", "top"],
    queryFn: () => doctorService.getTopDoctors(25),
  });
