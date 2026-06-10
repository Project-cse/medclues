import api from "@/services/api";
import {
  mapHospital,
  unwrapList,
  assertSuccess,
} from "@/services/mappers";
import type { Hospital } from "@/types/domain";

type Raw = Record<string, unknown>;

export const hospitalService = {
  async getAll(params?: { search?: string }): Promise<Hospital[]> {
    const { data } = await api.get<Raw>("/api/hospital-tieup/list");
    assertSuccess(data);
    let list = unwrapList(data, ["hospitals", "hospitalTieups", "data"]).map(mapHospital);

    const q = params?.search?.trim().toLowerCase();
    if (q) {
      list = list.filter(
        (h) =>
          h.name.toLowerCase().includes(q) ||
          h.address.toLowerCase().includes(q)
      );
    }
    return list;
  },

  async getById(id: string | number): Promise<Hospital> {
    const { data } = await api.get<Raw>(`/api/hospital-tieup/details/${id}`);
    assertSuccess(data);
    const hospital = (data.hospital ?? data) as Raw;
    return mapHospital(hospital);
  },
};
