import api from "@/services/api";
import { mapSpecialty, unwrapList, assertSuccess } from "@/services/mappers";
import type { Specialty } from "@/types/domain";

type Raw = Record<string, unknown>;

export const specialityService = {
  async getAll(): Promise<Specialty[]> {
    const { data } = await api.get<Raw>("/api/specialty/public/all");
    assertSuccess(data);
    return unwrapList(data, ["data", "specialties", "specialities"]).map(mapSpecialty);
  },
};
