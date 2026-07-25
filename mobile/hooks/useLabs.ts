import { useQuery } from "@tanstack/react-query";
import { labService } from "@/services/labs";

export const useLabs = (params?: { search?: string; openNow?: boolean }) =>
  useQuery({
    queryKey: ["labs", params],
    queryFn: () => labService.getAll(params),
  });

export const useLab = (id: string | number | undefined) =>
  useQuery({
    queryKey: ["lab", id],
    queryFn: () => labService.getById(id!),
    enabled: id != null && id !== "",
  });
