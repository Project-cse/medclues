import { useQuery } from "@tanstack/react-query";
import { bloodBankService } from "@/services/bloodbanks";

export const useBloodBanks = (params?: { search?: string }) =>
  useQuery({
    queryKey: ["bloodbanks", params],
    queryFn: () => bloodBankService.getAll(params),
  });

export const useBloodBank = (id: string | number | undefined) =>
  useQuery({
    queryKey: ["bloodbank", id],
    queryFn: () => bloodBankService.getById(id!),
    enabled: id != null && id !== "",
  });
