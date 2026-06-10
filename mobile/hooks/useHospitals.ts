import { useQuery } from "@tanstack/react-query";
import { hospitalService } from "@/services/hospitals";

export const useHospitals = (params?: { search?: string }) =>
  useQuery({
    queryKey: ["hospitals", params],
    queryFn: () => hospitalService.getAll(params),
  });

export const useHospital = (id: string | number | undefined) =>
  useQuery({
    queryKey: ["hospital", id],
    queryFn: () => hospitalService.getById(id!),
    enabled: id != null && id !== "",
  });
