/** Domain models aligned with FastAPI responses */

export type UserRole = "doctor" | "admin" | "dean" | "patient" | "nurse";

export interface User {
  id: string | number;
  name: string;
  email?: string;
  role: UserRole;
  branch_id: number | null;
  phone?: string;
  image?: string;
}

export interface Patient {
  id: string | number;
  name: string;
  email?: string;
  phone?: string;
  image?: string;
  gender?: string;
  age?: number | string;
  bloodGroup?: string;
  branch_id?: number | null;
  lastVisit?: string;
  condition?: string;
}

export interface Appointment {
  id: string | number;
  patientName?: string;
  patientId?: string | number;
  doctorId?: string | number;
  doctorName?: string;
  slotDate?: string;
  slotTime?: string;
  status?: string;
  amount?: number;
  payment?: boolean;
  isCompleted?: boolean;
  hospitalId?: number;
  userData?: { name?: string; phone?: string; email?: string };
  docData?: { name?: string; speciality?: string };
}

export interface ScheduleSlot {
  id?: string | number;
  slotDate: string;
  slotTime?: string;
  status?: string;
  patientName?: string;
  appointmentId?: string | number;
  queueLength?: number;
}

export interface ScheduleDay {
  date: string;
  slots: ScheduleSlot[];
  queueStatus?: string;
  queueLength?: number;
}

export interface BillingSummary {
  revenueToday: number;
  revenueTotal?: number;
  currency?: string;
  paidAppointments?: number;
  pendingPayments?: number;
  pendingAmount?: number;
  chartData?: Record<string, unknown>;
}

export interface Notification {
  id: string;
  title: string;
  body: string;
  type: "appointment" | "payment" | "system" | "alert" | "emergency";
  read: boolean;
  createdAt: string;
  relatedId?: string | number;
}

export interface DashboardStats {
  appointments?: number;
  patients?: number;
  earnings?: number;
  revenueToday?: number;
  revenueTotal?: number;
  totalDoctors?: number;
  activeDoctors?: number;
  patientsToday?: number;
  latestAppointments?: Appointment[];
  chartData?: Record<string, unknown>;
  raw?: Record<string, unknown>;
}

export interface ApiSuccess<T = unknown> {
  success: boolean;
  message?: string;
  data?: T;
}

export interface LoginPayload {
  email: string;
  password: string;
  role: UserRole;
}

export interface LoginResult {
  token: string;
  user: User;
}

export interface OtpSendPayload {
  email: string;
}

export interface OtpVerifyPayload {
  email: string;
  otp: string;
}
