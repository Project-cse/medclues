export interface HospitalListItem {
  id: string | number;
  name: string;
  address?: string;
  image?: string;
  rating: number;
  reviews: number;
  services: string[];
}

export interface DoctorListItem {
  id: string | number;
  name: string;
  speciality: string;
  image?: string;
  experience: string;
  experienceLevel: string;
  rating: number;
  reviews: number;
  available: boolean;
  about?: string;
  degree?: string;
  fees?: number;
  address?: string;
  slots?: Record<string, unknown>;
}

export interface LabListItem {
  id: string | number;
  name: string;
  location?: string;
  city?: string;
  rating: number;
  reviews: number;
  services: string[];
  verified: boolean;
  openNow: boolean;
  image?: string;
  tests?: LabTest[];
}

export interface LabTest {
  name: string;
  price: number;
}

export interface BloodBankListItem {
  id: string | number;
  name: string;
  location?: string;
  rating: number;
  reviews: number;
  bloodGroups: string[];
  phone?: string;
  address?: string;
  about?: string;
  verified?: boolean;
  openNow?: boolean;
}

export interface RecordCategory {
  key: string;
  title: string;
  icon: string;
  color: string;
  bg: string;
  count: number;
}

export type AppointmentFilter = "upcoming" | "completed" | "cancelled";
