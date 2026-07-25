import { useQuery } from "@tanstack/react-query";
import { recordsService } from "@/services/records";

export const useRecordCounts = () =>
  useQuery({
    queryKey: ["records", "counts"],
    queryFn: () => recordsService.getCounts(),
  });
