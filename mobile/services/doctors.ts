import api from "@/services/api";
import {
  mapDoctor,
  unwrapList,
  assertSuccess,
} from "@/services/mappers";
import type { Doctor } from "@/types/domain";
import { matchesSpeciality } from "@/utils/specialityMatch";

type Raw = Record<string, unknown>;

async function fetchMergedDoctors(hospitalId?: number): Promise<Doctor[]> {
  const seen = new Set<string>();
  const merged: Doctor[] = [];

  const add = (list: Raw[]) => {
    for (const raw of list) {
      const d = mapDoctor(raw);
      const key = String(d.id);
      if (seen.has(key)) continue;
      seen.add(key);
      merged.push(d);
    }
  };

  try {
    const { data } = await api.get<Raw>("/api/hospital-tieup/public/doctors");
    if (data.success !== false) add(unwrapList(data, ["doctors"]));
  } catch {
    /* optional */
  }

  const params = hospitalId != null ? { hospitalId } : {};
  const { data } = await api.get<Raw>("/api/doctor/list", { params });
  if (data.success !== false) add(unwrapList(data, ["doctors"]));

  return merged;
}

export const doctorService = {
  getAll: (params?: { search?: string; speciality?: string; hospitalId?: number }) =>
    fetchMergedDoctors(params?.hospitalId).then((list) => {
      let out = list;
      const q = params?.search?.trim().toLowerCase();
      if (q) {
        out = out.filter(
          (d) =>
            d.name.toLowerCase().includes(q) ||
            d.specialization.toLowerCase().includes(q) ||
            matchesSpeciality(d.specialization, q)
        );
      }
      if (params?.speciality) {
        const s = params.speciality;
        out = out.filter((d) => matchesSpeciality(d.specialization, s));
      }
      return out;
    }),

  async getById(id: string | number): Promise<Doctor> {
    const { data } = await api.get<Raw>(`/api/doctor/${id}`);
    assertSuccess(data);
    if (!data.doctor) throw new Error("Doctor not found");
    return mapDoctor(data.doctor as Raw);
  },

  async getTopDoctors(limit = 25): Promise<Doctor[]> {
    const all = await fetchMergedDoctors()
      .then((list) => list.filter((d) => d.available !== false))
      .then((list) => list.sort((a, b) => (b.rating ?? 0) - (a.rating ?? 0)));

    const picked: Doctor[] = [];
    const seenSpec = new Set<string>();

    for (const d of all) {
      const key = d.specialization.toLowerCase().trim() || "general";
      if (seenSpec.has(key)) continue;
      seenSpec.add(key);
      picked.push(d);
      if (picked.length >= limit) break;
    }

    if (picked.length < limit) {
      for (const d of all) {
        if (picked.some((p) => p.id === d.id)) continue;
        picked.push(d);
        if (picked.length >= limit) break;
      }
    }

    return picked;
  },
};
