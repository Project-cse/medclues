import api from "@/services/api";
import {
  getStats,
  getAllAppointments,
  getAllNotifications,
  markNotificationRead,
} from "@/services/staffApi";
import type { Appointment } from "@/types/api";

type JsonRecord = Record<string, unknown>;

export async function fetchAdminDashboard() {
  const [stats, appointments] = await Promise.all([getStats(), getAllAppointments()]);
  return { stats, appointments: appointments.slice(0, 8) };
}

export async function fetchAdminWeeklyDashboard() {
  const stats = await getStats();
  const appointments = await getAllAppointments();
  return { stats, appointments };
}

export async function fetchAdminAppointments(status?: string, search?: string) {
  let list = await getAllAppointments();
  if (status && status !== "all") {
    const s = status.toLowerCase();
    list = list.filter((a) => {
      if (s === "completed") return a.isCompleted;
      if (s === "cancelled") return (a.status ?? "").toLowerCase().includes("cancel");
      if (s === "confirmed") return a.payment && !a.isCompleted;
      return true;
    });
  }
  if (search?.trim()) {
    const q = search.toLowerCase();
    list = list.filter((a) => (a.patientName ?? "").toLowerCase().includes(q));
  }
  return list;
}

export async function fetchAdminPatients(search?: string) {
  const { data } = await api.get<JsonRecord>("/api/admin/users");
  let users = (data.users ?? []) as JsonRecord[];
  users = users.filter((u) => (u.role ?? "patient") === "patient" || !u.role);
  if (search?.trim()) {
    const q = search.toLowerCase();
    users = users.filter((u) => String(u.name ?? "").toLowerCase().includes(q));
  }
  return users.map((u) => ({
    id: u.id ?? u._id,
    name: String(u.name ?? "User"),
    email: u.email as string | undefined,
    phone: u.phone as string | undefined,
    gender: u.gender as string | undefined,
    image: u.image as string | undefined,
  }));
}

export async function fetchAdminDoctors(search?: string) {
  const { data } = await api.get<JsonRecord>("/api/admin/all-doctors");
  let list = (data.doctors ?? []) as JsonRecord[];
  if (search?.trim()) {
    const q = search.toLowerCase();
    list = list.filter((d) => String(d.name ?? "").toLowerCase().includes(q));
  }
  return list.map((d) => ({
    id: d.id ?? d._id,
    name: String(d.name ?? "Doctor"),
    speciality: String(d.speciality ?? "General"),
    degree: String(d.degree ?? ""),
    image: d.image as string | undefined,
    active: Boolean(d.available ?? true),
  }));
}

export async function toggleDoctorStatus(docId: string | number) {
  await api.post("/api/admin/change-availability", { docId: String(docId) });
}

export async function fetchAdminLabs() {
  const { data } = await api.get<JsonRecord>("/api/lab/list");
  return (data.labs ?? data.data ?? []) as JsonRecord[];
}

export async function fetchAdminBloodBanks() {
  const { data } = await api.get<JsonRecord>("/api/blood-bank/list");
  return (data.bloodBanks ?? data.banks ?? []) as JsonRecord[];
}

export async function fetchAdminUsers(search?: string) {
  const { data } = await api.get<JsonRecord>("/api/admin/users");
  let users = (data.users ?? []) as JsonRecord[];
  if (search?.trim()) {
    const q = search.toLowerCase();
    users = users.filter(
      (u) =>
        String(u.name ?? "").toLowerCase().includes(q) ||
        String(u.email ?? "").toLowerCase().includes(q)
    );
  }
  return users.map((u) => ({
    id: u.id ?? u._id,
    name: String(u.name ?? "User"),
    email: String(u.email ?? ""),
    role: String(u.role ?? "patient"),
    active: u.is_active !== false,
    image: u.image as string | undefined,
  }));
}

export async function fetchAdminReports() {
  const stats = await getStats();
  return [
    { id: "appointments", title: "Appointments Report", subtitle: `${stats.appointments} total` },
    { id: "patients", title: "Patients Report", subtitle: `${stats.patients} patients` },
    { id: "doctors", title: "Doctors Report", subtitle: `${stats.totalDoctors} doctors` },
    { id: "revenue", title: "Revenue Report", subtitle: `₹${stats.revenueTotal ?? 0}` },
    { id: "labs", title: "Lab Reports", subtitle: "Lab test analytics" },
    { id: "blood", title: "Blood Bank Report", subtitle: "Blood bank analytics" },
    { id: "download", title: "Download Center", subtitle: "Export all reports" },
  ];
}

export { getAllNotifications as fetchAdminNotifications, markNotificationRead };
export type { Appointment };
