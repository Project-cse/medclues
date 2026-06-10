import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { doctorService } from "@/services/doctors";
import { hospitalService } from "@/services/hospitals";
import { labService } from "@/services/labs";
import { HOME_SPECIALITIES } from "@/constants/homeSpecialities";
import { matchesSpeciality } from "@/utils/specialityMatch";

const QUICK_SERVICES = [
  { label: "Hospitals", route: "/hospitals", keywords: ["hospital", "clinic"] },
  { label: "Doctors", route: "/doctors", keywords: ["doctor", "physician"] },
  { label: "Labs", route: "/labs", keywords: ["lab", "test", "diagnostic"] },
  { label: "Blood Banks", route: "/labs", tab: "blood", keywords: ["blood", "bank", "donor"] },
  { label: "Pharmacy", route: "", keywords: ["pharmacy", "medicine", "drug"] },
  { label: "Insurance", route: "", keywords: ["insurance", "claim"] },
  { label: "Emergency", route: "/emergency", keywords: ["emergency", "urgent", "ambulance"] },
] as const;

export type HomeSearchResult =
  | { type: "service"; label: string; route: string; tab?: string }
  | { type: "speciality"; label: string; filterKey: string }
  | { type: "doctor"; id: string | number; name: string; specialization: string }
  | { type: "hospital"; id: string | number; name: string; address: string }
  | { type: "lab"; id: string | number; name: string; address: string };

export function useHomeSearch(query: string) {
  const q = query.trim().toLowerCase();
  const enabled = q.length >= 1;

  const doctorsQ = useQuery({
    queryKey: ["doctors", "home-search"],
    queryFn: () => doctorService.getAll(),
    staleTime: 60_000,
  });

  const hospitalsQ = useQuery({
    queryKey: ["hospitals", "home-search"],
    queryFn: () => hospitalService.getAll(),
    staleTime: 60_000,
  });

  const labsQ = useQuery({
    queryKey: ["labs", "home-search"],
    queryFn: () => labService.getAll(),
    staleTime: 60_000,
  });

  const results = useMemo((): HomeSearchResult[] => {
    if (!enabled) return [];

    const out: HomeSearchResult[] = [];

    for (const s of QUICK_SERVICES) {
      if (
        s.label.toLowerCase().includes(q) ||
        s.keywords.some((k) => k.includes(q) || q.includes(k))
      ) {
        out.push({
          type: "service",
          label: s.label,
          route: s.route,
          tab: "tab" in s ? s.tab : undefined,
        });
      }
    }

    for (const sp of HOME_SPECIALITIES) {
      if (
        sp.name.toLowerCase().includes(q) ||
        sp.filterKey.includes(q) ||
        matchesSpeciality(sp.name, q)
      ) {
        out.push({ type: "speciality", label: sp.name, filterKey: sp.filterKey });
      }
    }

    const doctors = doctorsQ.data ?? [];
    for (const d of doctors) {
      if (
        d.name.toLowerCase().includes(q) ||
        d.specialization.toLowerCase().includes(q) ||
        matchesSpeciality(d.specialization, q)
      ) {
        out.push({
          type: "doctor",
          id: d.id,
          name: d.name,
          specialization: d.specialization,
        });
      }
    }

    const hospitals = hospitalsQ.data ?? [];
    for (const h of hospitals) {
      if (h.name.toLowerCase().includes(q) || h.address.toLowerCase().includes(q)) {
        out.push({
          type: "hospital",
          id: h.id,
          name: h.name,
          address: h.address,
        });
      }
    }

    const labs = labsQ.data ?? [];
    for (const l of labs) {
      if (l.name.toLowerCase().includes(q) || l.address.toLowerCase().includes(q)) {
        out.push({
          type: "lab",
          id: l.id,
          name: l.name,
          address: l.address,
        });
      }
    }

    const seen = new Set<string>();
    return out.filter((r) => {
      const key =
        r.type === "doctor"
          ? `d-${r.id}`
          : r.type === "hospital"
            ? `h-${r.id}`
            : r.type === "speciality"
              ? `s-${r.filterKey}`
              : r.type === "lab"
                ? `l-${r.id}`
                : `v-${r.label}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    }).slice(0, 12);
  }, [q, enabled, doctorsQ.data, hospitalsQ.data, labsQ.data]);

  return {
    results,
    loading: enabled && (doctorsQ.isLoading || hospitalsQ.isLoading || labsQ.isLoading),
    hasQuery: enabled,
  };
}
