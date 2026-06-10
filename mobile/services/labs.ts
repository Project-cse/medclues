import api from "@/services/api";
import { mapLab, unwrapList, assertSuccess } from "@/services/mappers";
import type { Lab } from "@/types/domain";

type Raw = Record<string, unknown>;

export const labService = {
  async getAll(params?: { search?: string; openNow?: boolean }): Promise<Lab[]> {
    const { data } = await api.get<Raw>("/api/lab/list");
    assertSuccess(data);
    let list = unwrapList(data, ["labs"]).map(mapLab);

    const q = params?.search?.trim().toLowerCase();
    if (q) {
      list = list.filter(
        (l) =>
          l.name.toLowerCase().includes(q) ||
          l.address.toLowerCase().includes(q)
      );
    }
    if (params?.openNow) list = list.filter((l) => l.isOpen);
    return list;
  },

  async getById(id: string | number): Promise<Lab> {
    const all = await this.getAll();
    const found = all.find((l) => String(l.id) === String(id));
    if (!found) throw new Error("Lab not found");
    return found;
  },
};
