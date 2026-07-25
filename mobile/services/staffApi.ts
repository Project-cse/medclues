/**
 * Staff / admin / doctor / dean API — uses shared axios client.
 */
import AsyncStorage from "@react-native-async-storage/async-storage";
import api from "@/services/api";
import { STORAGE_KEYS } from "@/constants/config";
import { useAuthStore } from "@/store/authStore";
import { loginWithRole, logout as authLogout } from "@/services/auth";
import type {
  ApiSuccess,
  Appointment,
  BillingSummary,
  DashboardStats,
  LoginPayload,
  LoginResult,
  Notification,
  OtpSendPayload,
  OtpVerifyPayload,
  Patient,
  ScheduleDay,
  User,
  UserRole,
} from "@/types/api";

export type {
  ApiSuccess,
  Appointment,
  BillingSummary,
  DashboardStats,
  LoginPayload,
  LoginResult,
  Notification,
  OtpSendPayload,
  OtpVerifyPayload,
  Patient,
  ScheduleDay,
  User,
  UserRole,
} from "@/types/api";

type JsonRecord = Record<string, unknown>;

function unwrap<T>(data: JsonRecord, keys: string[]): T | undefined {
  for (const key of keys) {
    if (data[key] !== undefined) return data[key] as T;
  }
  return undefined;
}

function getTodaySlotDateVariants(): string[] {
  const now = new Date();
  const d = now.getDate();
  const m = now.getMonth() + 1;
  const y = now.getFullYear();
  return [
    `${String(d).padStart(2, "0")}_${String(m).padStart(2, "0")}_${y}`,
    `${d}_${m}_${y}`,
  ];
}

function isTodaySlotDate(slotDate?: string): boolean {
  if (!slotDate) return false;
  return getTodaySlotDateVariants().includes(slotDate);
}

function roleBasePath(role: UserRole): string {
  switch (role) {
    case "admin":
      return "/api/admin";
    case "doctor":
      return "/api/doctor";
    case "dean":
      return "/api/dean";
    default:
      return "/api/user";
  }
}

function requireRole(): UserRole {
  const role = useAuthStore.getState().user?.role;
  if (!role) throw new Error("Not authenticated");
  return role;
}

function mapPatient(raw: JsonRecord): Patient {
  return {
    id: (raw.id ?? raw._id) as string | number,
    name: String(raw.name ?? "Unknown"),
    email: raw.email as string | undefined,
    phone: raw.phone as string | undefined,
    image: raw.image as string | undefined,
    gender: raw.gender as string | undefined,
    age: raw.age as number | string | undefined,
    bloodGroup: (raw.bloodGroup ?? raw.blood_group) as string | undefined,
    branch_id: (raw.branch_id ?? raw.hospitalId ?? raw.hospital_id) as number | null | undefined,
  };
}

function mapAppointment(raw: JsonRecord): Appointment {
  const userData = raw.userData as JsonRecord | undefined;
  const docData = raw.docData as JsonRecord | undefined;
  return {
    id: (raw.id ?? raw._id) as string | number,
    patientName: (raw.patientName ?? userData?.name ?? raw.user_name) as string | undefined,
    patientId: (raw.user_id ?? raw.userId ?? userData?.id) as string | number | undefined,
    doctorId: (raw.doctor_id ?? raw.doctorId ?? docData?.id) as string | number | undefined,
    doctorName: (raw.doctorName ?? docData?.name) as string | undefined,
    slotDate: (raw.slot_date ?? raw.slotDate) as string | undefined,
    slotTime: (raw.slot_time ?? raw.slotTime) as string | undefined,
    status: raw.status as string | undefined,
    amount: raw.amount != null ? Number(raw.amount) : undefined,
    payment: Boolean(raw.payment),
    isCompleted: Boolean(raw.is_completed ?? raw.isCompleted),
    hospitalId: raw.hospital_id as number | undefined,
    userData: userData as Appointment["userData"],
    docData: docData as Appointment["docData"],
  };
}

async function resolveUserAfterLogin(
  role: UserRole,
  token: string,
  email: string,
  loginBody?: JsonRecord
): Promise<User> {
  const headers = { Authorization: `Bearer ${token}`, token };

  if (role === "dean" && loginBody?.dean) {
    const dean = loginBody.dean as JsonRecord;
    return {
      id: dean.id as string | number,
      name: String(dean.name ?? "Dean"),
      email: String(dean.email ?? email),
      role: "dean",
      branch_id: (dean.hospitalId ?? dean.hospital_id) as number | null,
    };
  }

  if (role === "doctor") {
    const { data } = await api.get<JsonRecord>("/api/doctor/profile", { headers });
    const profile = (data.profileData ?? data.profile) as JsonRecord;
    return {
      id: profile?.id as string | number,
      name: String(profile?.name ?? email),
      email: String(profile?.email ?? email),
      role: "doctor",
      branch_id: (profile?.hospitalId ?? profile?.hospital_id ?? null) as number | null,
    };
  }

  if (role === "patient") {
    const { data } = await api.get<JsonRecord>("/api/user/get-profile", { headers });
    const u = (data.userData ?? data.user) as JsonRecord;
    return {
      id: u?.id as string | number,
      name: String(u?.name ?? email),
      email: String(u?.email ?? email),
      role: "patient",
      branch_id: null,
      phone: u?.phone as string | undefined,
      image: u?.image as string | undefined,
    };
  }

  return {
    id: email,
    name: email.split("@")[0] ?? "Admin",
    email,
    role: "admin",
    branch_id: null,
  };
}

async function fetchAppointmentsForRole(role: UserRole): Promise<Appointment[]> {
  const base = roleBasePath(role);
  const { data } = await api.get<JsonRecord>(`${base}/appointments`);
  const list =
    (unwrap<unknown[]>(data, ["appointments", "data"]) ??
      (Array.isArray(data) ? data : [])) as JsonRecord[];
  return list.map(mapAppointment);
}

async function fetchPatientsForRole(role: UserRole): Promise<Patient[]> {
  if (role === "dean") {
    const { data } = await api.get<JsonRecord>("/api/dean/patients");
    return ((data.patients ?? []) as JsonRecord[]).map(mapPatient);
  }
  if (role === "admin") {
    const { data } = await api.get<JsonRecord>("/api/admin/users");
    return ((data.users ?? []) as JsonRecord[]).map(mapPatient);
  }
  const appointments = await fetchAppointmentsForRole(role);
  const seen = new Map<string | number, Patient>();
  appointments.forEach((apt) => {
    const id = apt.patientId ?? apt.patientName;
    if (id == null || seen.has(id)) return;
    seen.set(id, {
      id,
      name: apt.patientName ?? apt.userData?.name ?? "Patient",
      phone: apt.userData?.phone,
      email: apt.userData?.email,
    });
  });
  return Array.from(seen.values());
}

export async function login(payload: LoginPayload): Promise<LoginResult> {
  if (payload.role === "patient" || payload.role === "admin") {
    return loginWithRole(payload);
  }

  const endpoint = `${roleBasePath(payload.role)}/login`;
  const { data } = await api.post<JsonRecord>(endpoint, {
    email: payload.email.trim(),
    password: payload.password,
  });

  if (!data.success || !data.token) {
    throw new Error(String(data.message ?? "Invalid credentials"));
  }

  const user = await resolveUserAfterLogin(
    payload.role,
    String(data.token),
    payload.email.trim(),
    data
  );

  await useAuthStore.getState().setAuth(String(data.token), user);
  return { token: String(data.token), user };
}

export async function logout(): Promise<void> {
  await authLogout();
}

export async function sendOTP(payload: OtpSendPayload): Promise<ApiSuccess> {
  const { data } = await api.post<ApiSuccess>("/api/send-otp", { email: payload.email.trim() });
  return data;
}

export async function verifyOTP(payload: OtpVerifyPayload): Promise<ApiSuccess> {
  const { data } = await api.post<ApiSuccess>("/api/verify-otp", {
    email: payload.email.trim(),
    otp: payload.otp.trim(),
  });
  return data;
}

export async function getStats(): Promise<DashboardStats> {
  const role = requireRole();
  const { data } = await api.get<JsonRecord>(`${roleBasePath(role)}/dashboard`);
  const dash = (data.dashData ?? data.dashboard ?? data) as JsonRecord;
  return {
    appointments: Number(dash.appointments ?? dash.totalAppointments ?? 0),
    patients: Number(dash.patients ?? dash.totalPatients ?? 0),
    earnings: Number(dash.earnings ?? 0),
    revenueToday: Number(dash.revenueToday ?? 0),
    revenueTotal: Number(dash.revenueTotal ?? 0),
    totalDoctors: Number(dash.totalDoctors ?? 0),
    activeDoctors: Number(dash.activeDoctors ?? 0),
    patientsToday: Number(dash.patientsToday ?? 0),
    latestAppointments: ((dash.latestAppointments ?? dash.latest ?? []) as JsonRecord[]).map(
      mapAppointment
    ),
    chartData: dash.chartData as Record<string, unknown> | undefined,
    raw: data,
  };
}

export async function getRecentPatients(limit = 5): Promise<Patient[]> {
  const stats = await getStats();
  if (stats.latestAppointments?.length) {
    const patients: Patient[] = [];
    const seen = new Set<string>();
    for (const apt of stats.latestAppointments) {
      const key = String(apt.patientId ?? apt.patientName);
      if (seen.has(key)) continue;
      seen.add(key);
      patients.push({
        id: apt.patientId ?? key,
        name: apt.patientName ?? "Patient",
        phone: apt.userData?.phone,
        email: apt.userData?.email,
      });
      if (patients.length >= limit) break;
    }
    return patients;
  }
  return (await getAllPatients()).slice(0, limit);
}

export async function getAllPatients(): Promise<Patient[]> {
  return fetchPatientsForRole(requireRole());
}

export async function getPatientById(id: string | number): Promise<Patient> {
  const found = (await getAllPatients()).find((p) => String(p.id) === String(id));
  if (!found) throw new Error("Patient not found");
  return found;
}

export async function getTodayAppointments(): Promise<Appointment[]> {
  return (await getAllAppointments()).filter((a) => isTodaySlotDate(a.slotDate));
}

export async function getAllAppointments(): Promise<Appointment[]> {
  return fetchAppointmentsForRole(requireRole());
}

export async function getTodaySchedule(): Promise<ScheduleDay> {
  const role = requireRole();
  const todayLabel = getTodaySlotDateVariants()[0];

  if (role === "doctor") {
    const { data } = await api.get<JsonRecord>("/api/doctor/queue-status", {
      params: { slotDate: todayLabel },
    });
    const queue = (data.queueStatus ?? {}) as JsonRecord;
    const appointments = (queue.appointments ?? []) as JsonRecord[];
    return {
      date: todayLabel,
      queueStatus: queue.status as string | undefined,
      queueLength: Number(queue.queueLength ?? 0),
      slots: appointments.map((raw) => {
        const apt = mapAppointment(raw);
        return {
          id: apt.id,
          slotDate: apt.slotDate ?? todayLabel,
          slotTime: apt.slotTime,
          status: apt.status,
          patientName: apt.patientName,
          appointmentId: apt.id,
        };
      }),
    };
  }

  const todayAppointments = await getTodayAppointments();
  return {
    date: todayLabel,
    queueLength: todayAppointments.length,
    slots: todayAppointments.map((apt) => ({
      id: apt.id,
      slotDate: apt.slotDate ?? todayLabel,
      slotTime: apt.slotTime,
      status: apt.status,
      patientName: apt.patientName,
      appointmentId: apt.id,
    })),
  };
}

export async function getBillingSummary(): Promise<BillingSummary> {
  const role = requireRole();
  try {
    const analyticsPath =
      role === "dean"
        ? "/api/dean/revenue-analytics"
        : role === "admin"
          ? "/api/admin/revenue-analytics"
          : null;
    if (analyticsPath) {
      const { data } = await api.get<JsonRecord>(analyticsPath);
      const today = (data.today ?? data.hourly ?? {}) as JsonRecord;
      const values = Object.values(today).filter((v) => typeof v === "number") as number[];
      return {
        revenueToday: values.reduce((a, b) => a + b, 0),
        revenueTotal: Number(data.totalRevenue ?? 0),
        currency: "INR",
        chartData: data,
      };
    }
  } catch {
    /* fallback */
  }
  const stats = await getStats();
  const appointments = await getAllAppointments();
  return {
    revenueToday: stats.revenueToday ?? stats.earnings ?? 0,
    revenueTotal: stats.revenueTotal ?? stats.earnings ?? 0,
    currency: "INR",
    paidAppointments: appointments.filter((a) => a.payment).length,
    pendingPayments: appointments.filter((a) => !a.payment && !a.isCompleted).length,
    chartData: stats.chartData,
  };
}

async function getReadNotificationIds(): Promise<Set<string>> {
  const raw = await AsyncStorage.getItem(STORAGE_KEYS.readNotifications);
  if (!raw) return new Set();
  try {
    return new Set(JSON.parse(raw) as string[]);
  } catch {
    return new Set();
  }
}

async function saveReadNotificationIds(ids: Set<string>): Promise<void> {
  await AsyncStorage.setItem(
    STORAGE_KEYS.readNotifications,
    JSON.stringify(Array.from(ids))
  );
}

export async function getAllNotifications(): Promise<Notification[]> {
  const readIds = await getReadNotificationIds();
  const appointments = await getAllAppointments();
  return appointments
    .filter(
      (a) =>
        !a.isCompleted &&
        ["pending", "booked", ""].includes((a.status ?? "pending").toLowerCase())
    )
    .slice(0, 50)
    .map((apt) => ({
      id: `apt-${apt.id}`,
      title: "Appointment",
      body: `${apt.patientName ?? "Patient"} — ${apt.slotDate ?? ""} ${apt.slotTime ?? ""}`,
      type: "appointment" as const,
      read: readIds.has(`apt-${apt.id}`),
      createdAt: new Date().toISOString(),
      relatedId: apt.id,
    }));
}

export async function markNotificationRead(notificationId: string): Promise<void> {
  const readIds = await getReadNotificationIds();
  readIds.add(notificationId);
  await saveReadNotificationIds(readIds);
}

export { api };
