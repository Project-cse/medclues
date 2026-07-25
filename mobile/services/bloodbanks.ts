import api from "@/services/api";
import { mapBloodBank, unwrapList, assertSuccess } from "@/services/mappers";
import type { BloodBank } from "@/types/domain";

type Raw = Record<string, unknown>;

export const bloodBankService = {
  async getAll(params?: { search?: string }): Promise<BloodBank[]> {
    const { data } = await api.get<Raw>("/api/blood-bank/list");
    assertSuccess(data);
    let list = unwrapList(data, ["bloodBanks", "blood_banks"]).map(mapBloodBank);

    const q = params?.search?.trim().toLowerCase();
    if (q) {
      list = list.filter(
        (b) =>
          b.name.toLowerCase().includes(q) ||
          b.address.toLowerCase().includes(q)
      );
    }
    return list;
  },

  async getById(id: string | number): Promise<BloodBank> {
    const all = await this.getAll();
    const found = all.find((b) => String(b.id) === String(id));
    if (!found) throw new Error("Blood bank not found");
    return found;
  },
};
