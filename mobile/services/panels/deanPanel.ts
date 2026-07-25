import api from "@/services/api";
import { getStats, getAllAppointments, getAllPatients } from "@/services/staffApi";
import type { Appointment, Patient } from "@/types/api";

type JsonRecord = Record<string, unknown>;

export async function fetchDeanDashboard() {
  const [stats, appointments, patients, hospitalRes] = await Promise.all([
    getStats(),
    getAllAppointments(),
    getAllPatients(),
    api.get<JsonRecord>("/api/dean/hospital").catch(() => ({ data: {} as JsonRecord })),
  ]);
  const hospitalData = hospitalRes.data as JsonRecord;
  const hospital = (hospitalData.hospital ?? hospitalData) as JsonRecord;
  const doctorsRes = await api.get<JsonRecord>("/api/dean/doctors");
  const doctors = (doctorsRes.data.doctors ?? []) as JsonRecord[];
  return {
    stats,
    appointments,
    patients,
    hospital,
    doctors,
    pendingApprovals: appointments.filter(
      (a) => !a.isCompleted && (a.status ?? "").toLowerCase() === "pending"
    ).length,
    activities: appointments.slice(0, 6).map((a) => ({
      id: String(a.id),
      title: `Appointment — ${a.patientName ?? "Patient"}`,
      subtitle: a.doctorName ?? "Doctor",
      time: a.slotDate,
    })),
  };
}

export async function fetchDeanStudents(search?: string): Promise<Patient[]> {
  let list = await getAllPatients();
  if (search?.trim()) {
    const q = search.toLowerCase();
    list = list.filter(
      (p) =>
        p.name.toLowerCase().includes(q) ||
        String(p.email ?? "").toLowerCase().includes(q)
    );
  }
  return list;
}

export async function fetchDeanFaculty(search?: string) {
  const { data } = await api.get<JsonRecord>("/api/dean/doctors");
  let list = (data.doctors ?? []) as JsonRecord[];
  if (search?.trim()) {
    const q = search.toLowerCase();
    list = list.filter((d) => String(d.name ?? "").toLowerCase().includes(q));
  }
  return list.map((d) => ({
    id: d.id ?? d._id,
    name: String(d.name ?? "Doctor"),
    designation: String(d.speciality ?? d.degree ?? "Faculty"),
    department: String(d.speciality ?? "General"),
    image: d.image as string | undefined,
    active: Boolean(d.available ?? true),
  }));
}

const DEPARTMENTS = [
  "General Medicine",
  "Cardiology",
  "Neurology",
  "Orthopedics",
  "Pediatrics",
  "Psychiatry",
  "Dermatology",
  "Ophthalmology",
];

export async function fetchDeanDepartments() {
  const faculty = await fetchDeanFaculty();
  const patients = await getAllPatients();
  return DEPARTMENTS.map((name, i) => ({
    id: i,
    name,
    facultyCount: Math.max(1, Math.floor(faculty.length / DEPARTMENTS.length)),
    studentCount: Math.max(0, Math.floor(patients.length / DEPARTMENTS.length)),
    color: ["#1565C0", "#00897B", "#7B1FA2", "#F57F17", "#C62828", "#5D4037", "#00838F", "#6A1B9A"][i],
  }));
}

export async function fetchDeanApprovals(status: "pending" | "completed") {
  const appointments = await getAllAppointments();
  const pending = appointments
    .filter((a) => !a.isCompleted && !a.payment)
    .slice(0, 10)
    .map((a, i) => ({
      id: String(a.id),
      type: ["Leave Request", "Student Enrollment", "Exam Schedule", "Budget Request"][i % 4],
      requesterName: a.patientName ?? "Unknown",
      date: a.slotDate,
      description: `Appointment request for ${a.slotTime ?? "—"}`,
      status: "pending" as const,
    }));
  if (status === "pending") return pending;
  return appointments
    .filter((a) => a.isCompleted)
    .slice(0, 10)
    .map((a) => ({
      id: String(a.id),
      type: "Appointment",
      requesterName: a.patientName ?? "Unknown",
      date: a.slotDate,
      description: "Completed",
      status: "completed" as const,
    }));
}

export async function approveDeanItem(id: string) {
  console.warn("[deanPanel] approve", id);
}

export async function rejectDeanItem(id: string) {
  console.warn("[deanPanel] reject", id);
}

export async function fetchDeanReports() {
  const [patients, faculty] = await Promise.all([getAllPatients(), fetchDeanFaculty()]);
  return [
    { id: "students", title: "Students Report", subtitle: `${patients.length} students` },
    { id: "faculty", title: "Faculty Report", subtitle: `${faculty.length} members` },
    { id: "attendance", title: "Attendance Report", subtitle: "View attendance analytics" },
    { id: "exam", title: "Exam Report", subtitle: "View exam results" },
    { id: "department", title: "Department Report", subtitle: "Department analytics" },
    { id: "financial", title: "Financial Report", subtitle: "Revenue summary" },
    { id: "library", title: "Library Report", subtitle: "Library analytics" },
    { id: "hostel", title: "Hostel Report", subtitle: "Hostel analytics" },
  ];
}

export async function fetchDeanNotices() {
  return [
    {
      id: "1",
      title: "Exam Schedule Published",
      description: "Final year exams begin next Monday.",
      date: new Date().toISOString(),
      type: "schedule" as const,
    },
    {
      id: "2",
      title: "Holiday Notice",
      description: "Campus closed on public holiday.",
      date: new Date().toISOString(),
      type: "important" as const,
    },
  ];
}

export async function fetchDeanMessages() {
  const patients = await getAllPatients();
  return patients.slice(0, 12).map((p, i) => ({
    id: String(p.id),
    name: p.name,
    preview: "Tap to open conversation",
    time: "Recently",
    unread: i < 2 ? 1 : 0,
    image: p.image,
  }));
}

export type { Appointment, Patient };
