import apiClient from "@/src/api/apiClient";

export type HourAmount = { hour: string; amount: number };
export type RoleCount = { role: string; count: number };
export type HourCount = { hour: string; count: number };
export type DeptCount = { dept: string; count: number };
export type StatusCount = { status: string; count: number };
export type DayAmount = { day: string; amount: number };

export type AdminChartStats = {
  paymentsToday: HourAmount[];
  usersByRole: RoleCount[];
  appointmentsPerHour: HourCount[];
};

export type DeanChartStats = {
  deptLoad: DeptCount[];
  doctorAvailability: StatusCount[];
  weeklyRevenue: DayAmount[];
};

export type DoctorChartStats = {
  myAppointments: StatusCount[];
  queueLength: number;
  weeklyEarnings: DayAmount[];
};

export async function getAdminStats(): Promise<AdminChartStats> {
  const { data } = await apiClient.get<AdminChartStats>("/api/charts/admin");
  return {
    paymentsToday: data.paymentsToday ?? [],
    usersByRole: data.usersByRole ?? [],
    appointmentsPerHour: data.appointmentsPerHour ?? [],
  };
}

export async function getDeanStats(): Promise<DeanChartStats> {
  const { data } = await apiClient.get<DeanChartStats>("/api/charts/dean");
  return {
    deptLoad: data.deptLoad ?? [],
    doctorAvailability: data.doctorAvailability ?? [],
    weeklyRevenue: data.weeklyRevenue ?? [],
  };
}

export async function getDoctorStats(): Promise<DoctorChartStats> {
  const { data } = await apiClient.get<DoctorChartStats>("/api/charts/doctor");
  return {
    myAppointments: data.myAppointments ?? [],
    queueLength: data.queueLength ?? 0,
    weeklyEarnings: data.weeklyEarnings ?? [],
  };
}
