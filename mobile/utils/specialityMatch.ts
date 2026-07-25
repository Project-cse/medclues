const SPECIALITY_ALIASES: Record<string, string[]> = {
  cardiology: ["cardiol", "cardiac", "heart"],
  orthopedics: ["orthop", "orthopaedic", "bone", "ortho"],
  psychiatry: ["psychiat", "psych", "psychiatrist"],
  ophthalmology: ["ophthal", "eye", "optomet"],
  ent: ["otolaryng", "ear", "throat", "ent"],
  dentistry: ["dental", "dentist", "tooth", "oral"],
  "general medicine": ["general physician", "general medic", "physician", "gp", "internal"],
  gynecology: ["gynec", "gynaec", "obstetric", "obgyn"],
  dermatology: ["dermat", "skin"],
  pediatrics: ["pediatr", "paediatr", "child", "paediatric"],
  neurology: ["neurolog", "neuro", "brain"],
  gastroenterology: ["gastro", "gastroenterol", "digest"],
};

/** Match doctor specialization against a home speciality label or search token. */
export function matchesSpeciality(specialization: string, query: string): boolean {
  const spec = specialization.toLowerCase().trim();
  const target = query.toLowerCase().trim();
  if (!spec || !target) return false;
  if (spec.includes(target) || target.includes(spec)) return true;

  const aliases = SPECIALITY_ALIASES[target] ?? [];
  if (aliases.some((a) => spec.includes(a))) return true;

  for (const [key, words] of Object.entries(SPECIALITY_ALIASES)) {
    if (target.includes(key) || key.includes(target)) {
      if (words.some((w) => spec.includes(w)) || spec.includes(key)) return true;
    }
  }

  if (target.length >= 3) {
    for (const [key, words] of Object.entries(SPECIALITY_ALIASES)) {
      if (target.includes(key.slice(0, 4)) || words.some((w) => target.includes(w.slice(0, 4)))) {
        if (spec.includes(key) || words.some((w) => spec.includes(w))) return true;
      }
    }
  }

  return false;
}
