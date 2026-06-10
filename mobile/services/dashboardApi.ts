import { api } from "@/services/staffApi";
import {
  getAllAppointments,
  getAllNotifications,
  getBillingSummary,
  getRecentPatients,
  getStats,
  getTodayAppointments,
  getTodaySchedule,
} from "@/services/staffApi";
import { useAuthStore } from "@/store/authStore";
import type { Appointment, BillingSummary, Notification } from "@/types/api";
import type {
  DashboardAppointment,
  DashboardStatsCards,
  PatientRecent,
} from "@/types/dashboard";
import type { ScheduleSlot } from "@/types/api";

type JsonRecord = Record<string, unknown>;

function authParams(): { branch_id?: number; doctor_id?: string | number; user_id?: string | number } {
  const user = useAuthStore.getState().user;
  return {
    branch_id: user?.branch_id ?? undefined,
    doctor_id: user?.role === "doctor" ? user.id : undefined,
    user_id: user?.id,
  };
}

async function tryUnifiedGet<T>(
  path: string,
  fallback: () => Promise<T>
): Promise<T> {
  try {
    const { data } = await api.get<JsonRecord>(path, { params: authParams() });
    if (data.success === false) throw new Error(String(data.message));
    const payload = (data.data ??
      data.stats ??
      data.appointments ??
      data.patients ??
      data.notifications ??
      data.slots ??
      data) as T;
    return payload;
  } catch {
    return fallback();
  }
}

export function mapAppointmentStatus(status?: string, isCompleted?: boolean): DashboardAppointment["statusKind"] {
  if (isCompleted || status?.toLowerCase() === "completed" || status?.toLowerCase() === "done") {
    return "done";
  }
  if (
    status?.toLowerCase() === "confirmed" ||
    status?.toLowerCase() === "booked" ||
    status?.toLowerCase() === "in-consult"
  ) {
    return "confirmed";
  }
  return "pending";
}

function enrichAppointment(apt: Appointment): DashboardAppointment {
  return {
    ...apt,
    statusKind: mapAppointmentStatus(apt.status, apt.isCompleted),
  };
}

export async function fetchDashboardStats(): Promise<DashboardStatsCards> {
  return tryUnifiedGet<DashboardStatsCards>("/api/dashboard/stats", async () => {
    const [stats, todayApts, billing] = await Promise.all([
      getStats(),
      getTodayAppointments(),
      getBillingSummary().catch(() => null),
    ]);
    return {
      patientsToday: stats.patientsToday ?? stats.patients ?? 0,
      appointmentsToday: todayApts.length,
      pendingBilling: billing?.pendingPayments ?? 0,
      newRegistrations: stats.patientsToday ?? 0,
    };
  });
}

export async function fetchTodayAppointmentsList(): Promise<DashboardAppointment[]> {
  const list = await tryUnifiedGet<Appointment[]>(
    "/api/appointments/today",
    () => getTodayAppointments()
  );
  const arr = Array.isArray(list) ? list : [];
  return arr.slice(0, 5).map((a) => enrichAppointment(a as Appointment));
}

export async function fetchRecentPatientsList(): Promise<PatientRecent[]> {
  const list = await tryUnifiedGet<PatientRecent[]>(
    "/api/patients/recent",
    async () => {
      const patients = await getRecentPatients(5);
      const appointments = await getAllAppointments();
      return patients.map((p) => {
        const lastApt = appointments.find(
          (a) => String(a.patientId) === String(p.id)
        );
        return {
          ...p,
          lastVisit: lastApt?.slotDate ?? "—",
          condition: lastApt?.docData?.speciality ?? p.bloodGroup ?? "General",
        };
      });
    }
  );
  return (Array.isArray(list) ? list : []).slice(0, 5);
}

export async function fetchTodayScheduleList(): Promise<ScheduleSlot[]> {
  const params = authParams();
  const schedule = await tryUnifiedGet<{ slots?: ScheduleSlot[] }>(
    "/api/schedule/today",
    () => getTodaySchedule()
  );
  if (Array.isArray(schedule)) return schedule as ScheduleSlot[];
  if (schedule && "slots" in schedule && Array.isArray(schedule.slots)) {
    return schedule.slots;
  }
  return (schedule as { slots: ScheduleSlot[] })?.slots ?? [];
}

export async function fetchBillingSummaryCard(): Promise<
  BillingSummary & { pendingAmount: number }
> {
  const summary = await tryUnifiedGet<BillingSummary & { pendingAmount?: number }>(
    "/api/billing/summary",
    async () => {
      const b = await getBillingSummary();
      const appointments = await getAllAppointments();
      const pendingAmount = appointments
        .filter((a) => !a.payment && !a.isCompleted)
        .reduce((sum, a) => sum + (a.amount ?? 0), 0);
      return { ...b, pendingAmount };
    }
  );
  const appointments = await getAllAppointments().catch(() => []);
  const pendingAmount =
    summary.pendingAmount ??
    appointments
      .filter((a) => !a.payment && !a.isCompleted)
      .reduce((sum, a) => sum + (a.amount ?? 0), 0);

  return {
    revenueToday: summary.revenueToday ?? 0,
    revenueTotal: summary.revenueTotal,
    currency: summary.currency ?? "INR",
    paidAppointments: summary.paidAppointments ?? 0,
    pendingPayments: summary.pendingPayments ?? 0,
    pendingAmount,
    chartData: summary.chartData,
  };
}

export async function fetchNotificationsList(): Promise<Notification[]> {
  const params = authParams();
  return tryUnifiedGet<Notification[]>("/api/notifications", () =>
    getAllNotifications()
  );
}

export async function fetchBranchName(): Promise<string> {
  const user = useAuthStore.getState().user;
  if (!user?.branch_id) {
    return user?.role === "admin" ? "All Branches" : "MediChain+ Hospital";
  }

  try {
    const { data } = await api.get<JsonRecord>("/api/dean/hospital");
    const hospital = (data.hospital ?? data.hospitalData ?? data) as JsonRecord;
    if (hospital?.name) return String(hospital.name);
  } catch {
    /* use fallback */
  }

  try {
    const { data } = await api.get<JsonRecord>(`/api/hospital/details/${user.branch_id}`);
    if (data?.name) return String(data.name);
    const nested = data.hospital as JsonRecord | undefined;
    if (nested?.name) return String(nested.name);
  } catch {
    /* use fallback */
  }

  return `Branch #${user.branch_id}`;
}
