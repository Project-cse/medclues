import type { Appointment, BillingSummary, Notification, Patient, ScheduleSlot } from "./api";

export interface DashboardStatItem {
  key: string;
  label: string;
  value: number;
  icon: string;
  bgClass: string;
  iconColor: string;
}

export interface DashboardStatsCards {
  patientsToday: number;
  appointmentsToday: number;
  pendingBilling: number;
  newRegistrations: number;
}

export interface PatientRecent extends Patient {
  lastVisit?: string;
  condition?: string;
}

export type AppointmentStatusKind = "confirmed" | "pending" | "done";

export interface DashboardAppointment extends Appointment {
  statusKind: AppointmentStatusKind;
}

export interface DashboardData {
  stats: DashboardStatsCards;
  appointmentsToday: DashboardAppointment[];
  recentPatients: PatientRecent[];
  scheduleSlots: ScheduleSlot[];
  billing: BillingSummary & { pendingAmount?: number };
  notifications: Notification[];
  branchName: string;
}
