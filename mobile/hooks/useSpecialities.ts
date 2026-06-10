import { useQuery } from "@tanstack/react-query";
import { specialityService } from "@/services/specialities";

export const useSpecialities = () =>
  useQuery({
    queryKey: ["specialities"],
    queryFn: () => specialityService.getAll(),
  });
