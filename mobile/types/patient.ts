import type { Appointment } from "./api";

export interface PatientProfile {
  id: string | number;
  name: string;
  email?: string;
  phone?: string;
  image?: string;
  gender?: string;
  age?: number | string;
  bloodGroup?: string;
  address?: { line1?: string; line2?: string };
}

export interface PatientAppointment extends Appointment {
  docId?: string | number;
  tokenNumber?: number;
  paymentMethod?: string;
  hospitalName?: string;
}

export interface DoctorCard {
  id: string | number;
  name: string;
  speciality: string;
  image?: string;
  fees?: number;
  experience?: string;
  hospitalName?: string;
  available?: boolean;
}

export interface HealthRecordItem {
  id: string | number;
  title?: string;
  recordType?: string;
  doctorName?: string;
  date?: string;
}

export interface HospitalItem {
  id: string | number;
  name: string;
  address?: string;
  image?: string;
}

export interface PatientDashboardData {
  profile: PatientProfile | null;
  appointments: PatientAppointment[];
  doctors: DoctorCard[];
  hospitals: HospitalItem[];
  healthRecords: HealthRecordItem[];
}
