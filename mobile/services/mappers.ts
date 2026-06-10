import type {
  Appointment,
  BloodBank,
  Doctor,
  Hospital,
  Lab,
  RecordCounts,
  Specialty,
  TimeSlot,
  UserProfile,
} from "@/types/domain";

type Raw = Record<string, unknown>;

function str(v: unknown, fallback = ""): string {
  return v != null ? String(v) : fallback;
}

function num(v: unknown): number | undefined {
  if (v == null || v === "") return undefined;
  const n = Number(v);
  return Number.isFinite(n) ? n : undefined;
}

function parseJsonArray(v: unknown): string[] {
  if (Array.isArray(v)) return v.map(String);
  if (typeof v === "string") {
    try {
      const parsed = JSON.parse(v) as unknown;
      if (Array.isArray(parsed)) return parsed.map(String);
    } catch {
      return v ? [v] : [];
    }
  }
  return [];
}

export function mapUser(raw: Raw): UserProfile {
  const addr = raw.address;
  return {
    id: (raw.id ?? raw._id) as string | number,
    name: str(raw.name, "Patient"),
    email: raw.email as string | undefined,
    phone: raw.phone as string | undefined,
    profilePicUrl: (raw.image ?? raw.profile_pic_url) as string | undefined,
    gender: raw.gender as string | undefined,
    dob: (raw.dob ?? raw.date_of_birth) as string | undefined,
    bloodGroup: (raw.bloodGroup ?? raw.blood_group) as string | undefined,
    address:
      typeof addr === "object" && addr !== null
        ? (addr as UserProfile["address"])
        : str(addr),
    createdAt: (raw.created_at ?? raw.createdAt) as string | undefined,
  };
}

export function mapHospital(raw: Raw): Hospital {
  const services: string[] = [];
  const spec = str(raw.specialization ?? raw.speciality);
  if (spec) services.push(spec);
  const type = str(raw.type ?? raw.hospitalType);
  if (type && type !== "General") services.push(type);

  return {
    id: (raw.id ?? raw._id) as string | number,
    name: str(raw.name ?? raw.hospitalName, "Hospital"),
    address: str(raw.address ?? raw.location),
    image: raw.image as string | undefined,
    contact: str(raw.contact) || undefined,
    specialization: spec || undefined,
    rating: num(raw.rating),
    reviewCount: num(raw.reviews ?? raw.review_count ?? raw.reviewCount),
    services,
    isOpen: raw.is_open !== false && raw.openNow !== false,
    isVerified: Boolean(raw.verified ?? raw.is_verified),
  };
}

export function mapDoctor(raw: Raw): Doctor {
  const addr = raw.address;
  let addressStr = "";
  if (typeof addr === "object" && addr !== null) {
    const a = addr as Raw;
    addressStr = [a.line1, a.line2].filter(Boolean).join(", ");
  } else if (typeof addr === "string") {
    addressStr = addr;
  }

  let slotsBooked: Record<string, string[]> | undefined;
  const sb = raw.slots_booked ?? raw.slotsBooked;
  if (sb && typeof sb === "object") {
    slotsBooked = sb as Record<string, string[]>;
  } else if (typeof sb === "string") {
    try {
      slotsBooked = JSON.parse(sb) as Record<string, string[]>;
    } catch {
      slotsBooked = undefined;
    }
  }

  return {
    id: (raw.id ?? raw._id) as string | number,
    name: str(raw.name, "Doctor"),
    specialization: str(
      raw.speciality ?? raw.specialization ?? raw.degree,
      "General Physician"
    ),
    profilePicUrl: (raw.image ?? raw.profile_pic_url) as string | undefined,
    experience: raw.experience as string | undefined,
    rating: num(raw.rating),
    reviewCount: num(raw.reviews ?? raw.review_count),
    about: raw.about as string | undefined,
    qualification: (raw.degree ?? raw.qualification) as string | undefined,
    education: (raw.education ?? raw.degree) as string | undefined,
    availableDays: (raw.available_days ?? raw.availableDays) as string | undefined,
    availableTime: (raw.available_time ?? raw.availableTime) as string | undefined,
    consultationFee: num(raw.fees ?? raw.consultation_fee),
    available: raw.available !== false,
    hospitalName: (raw.hospitalName ?? raw.hospital_name) as string | undefined,
    hospitalId: (raw.hospitalId ?? raw.hospital_id) as string | number | undefined,
    address: addressStr || undefined,
    slotsBooked,
  };
}

export function mapAppointment(raw: Raw): Appointment {
  const doc = (raw.docData ?? raw.doctor ?? {}) as Raw;
  const hospitalName = str(
    raw.hospitalName ?? raw.hospital_name ?? doc.hospitalName
  );

  const slotDate = str(raw.slotDate ?? raw.slot_date);
  const slotTime = str(raw.slotTime ?? raw.slot_time);

  let status = str(raw.status, "pending");
  if (raw.cancelled) status = "cancelled";
  else if (raw.isCompleted ?? raw.is_completed) status = "completed";

  return {
    id: (raw.id ?? raw._id) as string | number,
    doctor: {
      id: (doc.id ?? doc._id ?? raw.docId) as string | number | undefined,
      name: str(doc.name, "Doctor"),
      profilePicUrl: (doc.image ?? doc.profile_pic_url) as string | undefined,
      specialization: str(doc.speciality ?? doc.specialization),
    },
    hospital: {
      name: hospitalName || undefined,
      address: str(raw.location ?? raw.hospital_address),
    },
    date: slotDate,
    time: slotTime,
    status,
    isCompleted: Boolean(raw.isCompleted ?? raw.is_completed),
    cancelled: Boolean(raw.cancelled),
    amount: num(raw.amount),
    rawSlotDate: slotDate,
  };
}

export function mapLab(raw: Raw): Lab {
  return {
    id: raw.id as string | number,
    name: str(raw.name, "Lab"),
    address: str(raw.location ?? raw.city ?? raw.address),
    rating: num(raw.rating),
    reviewCount: num(raw.reviews ?? raw.review_count),
    availableTests: parseJsonArray(raw.services ?? raw.available_tests),
    isOpen: Boolean(raw.openNow ?? raw.open_now ?? true),
    isVerified: Boolean(raw.verified ?? raw.is_verified),
    image: raw.image as string | undefined,
  };
}

export function mapBloodBank(raw: Raw): BloodBank {
  const bloodRaw = raw.available_blood ?? raw.availableBlood ?? raw.blood_groups;
  let groups: string[] = [];
  if (typeof bloodRaw === "object" && bloodRaw !== null && !Array.isArray(bloodRaw)) {
    const obj = bloodRaw as Record<string, unknown>;
    groups = Object.entries(obj)
      .filter(([, qty]) => Number(qty) > 0)
      .map(([g]) => g);
  } else {
    groups = parseJsonArray(bloodRaw);
  }

  return {
    id: (raw.id ?? raw._id) as string | number,
    name: str(raw.name, "Blood Bank"),
    address: str(raw.location ?? raw.city ?? raw.address),
    rating: num(raw.rating),
    reviewCount: num(raw.reviews ?? raw.review_count),
    availableBloodGroups: groups,
    isOpen: raw.open_now !== false && raw.openNow !== false,
    isVerified: Boolean(raw.verified ?? raw.is_verified),
    phone: str(raw.phone ?? raw.contact) || undefined,
    about: str(raw.about ?? raw.description) || undefined,
    image: raw.image as string | undefined,
  };
}

export function mapSpecialty(raw: Raw): Specialty {
  return {
    id: (raw.id ?? raw._id) as string | number,
    name: str(raw.specialty_name ?? raw.specialtyName ?? raw.name),
    helpline: str(raw.helpline_number ?? raw.helplineNumber) || undefined,
    availability: str(raw.availability) || undefined,
  };
}

const RECORD_TYPE_MAP: Record<string, keyof RecordCounts> = {
  prescription: "prescriptions",
  prescriptions: "prescriptions",
  lab: "labReports",
  "lab report": "labReports",
  "lab reports": "labReports",
  history: "medicalHistory",
  "medical history": "medicalHistory",
  vaccination: "vaccinations",
  vaccine: "vaccinations",
  allergy: "allergies",
  allergies: "allergies",
  vitals: "vitals",
  vital: "vitals",
  general: "medicalHistory",
};

export function countRecordsByType(
  records: { recordType?: string }[]
): RecordCounts {
  const counts: RecordCounts = {
    prescriptions: 0,
    labReports: 0,
    medicalHistory: 0,
    vaccinations: 0,
    allergies: 0,
    vitals: 0,
  };

  for (const r of records) {
    const key = (r.recordType ?? "general").toLowerCase().trim();
    const field = RECORD_TYPE_MAP[key] ?? "medicalHistory";
    counts[field] += 1;
  }

  return counts;
}

export function unwrapList(data: Raw, keys: string[]): Raw[] {
  if (!data || typeof data !== "object") return [];
  const keyList = Array.isArray(keys) ? keys : [];
  for (const key of keyList) {
    const val = data[key];
    if (Array.isArray(val)) return val as Raw[];
  }
  if (Array.isArray(data)) return data as Raw[];
  return [];
}

export function assertSuccess(data: Raw, fallback = "Request failed"): void {
  if (data.success === false) {
    throw new Error(str(data.message, fallback));
  }
}

/** Parse /api/ai/doctor-slots response for a single date */
export function slotsForDate(
  availableSlots: Raw[],
  slotDate: string,
  bookedForDate: string[] = []
): TimeSlot[] {
  const day = availableSlots.find((d) => d.date === slotDate);
  if (!day || !Array.isArray(day.slots)) return [];

  return (day.slots as Raw[]).map((s) => {
    const time = str(s.time ?? s.displayTime);
    const booked = bookedForDate.some(
      (b) => b.toLowerCase() === time.toLowerCase() || b.includes(time)
    );
    return {
      time,
      displayTime: str(s.displayTime ?? s.time),
      available: !booked,
    };
  });
}
