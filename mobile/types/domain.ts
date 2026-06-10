export interface UserProfile {
  id: string | number;
  name: string;
  email?: string;
  phone?: string;
  profilePicUrl?: string;
  gender?: string;
  dob?: string;
  bloodGroup?: string;
  address?: { line1?: string; line2?: string } | string;
  createdAt?: string;
}

export interface Hospital {
  id: string | number;
  name: string;
  address: string;
  image?: string;
  contact?: string;
  specialization?: string;
  rating?: number;
  reviewCount?: number;
  services: string[];
  isOpen?: boolean;
  isVerified?: boolean;
}

export interface Doctor {
  id: string | number;
  name: string;
  specialization: string;
  profilePicUrl?: string;
  experience?: string;
  rating?: number;
  reviewCount?: number;
  about?: string;
  education?: string;
  qualification?: string;
  availableDays?: string;
  availableTime?: string;
  consultationFee?: number;
  available: boolean;
  hospitalName?: string;
  hospitalId?: string | number;
  address?: string;
  slotsBooked?: Record<string, string[]>;
}

export interface AppointmentDoctor {
  id?: string | number;
  name: string;
  profilePicUrl?: string;
  specialization?: string;
}

export interface AppointmentHospital {
  name?: string;
  address?: string;
}

export interface Appointment {
  id: string | number;
  doctor: AppointmentDoctor;
  hospital: AppointmentHospital;
  date: string;
  time: string;
  status: string;
  isCompleted: boolean;
  cancelled: boolean;
  amount?: number;
  rawSlotDate: string;
}

export interface Lab {
  id: string | number;
  name: string;
  address: string;
  rating?: number;
  reviewCount?: number;
  availableTests: string[];
  isOpen: boolean;
  isVerified: boolean;
  image?: string;
}

export interface LabTest {
  name: string;
  price?: number;
}

export interface BloodBank {
  id: string | number;
  name: string;
  address: string;
  rating?: number;
  reviewCount?: number;
  availableBloodGroups: string[];
  isOpen?: boolean;
  isVerified?: boolean;
  phone?: string;
  about?: string;
  image?: string;
}

export interface RecordCounts {
  prescriptions: number;
  labReports: number;
  medicalHistory: number;
  vaccinations: number;
  allergies: number;
  vitals: number;
}

export interface Specialty {
  id: string | number;
  name: string;
  helpline?: string;
  availability?: string;
}

export interface TimeSlot {
  time: string;
  displayTime: string;
  available: boolean;
}

export interface DaySlots {
  date: string;
  displayDate: string;
  slots: TimeSlot[];
}
