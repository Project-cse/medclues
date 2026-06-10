import api from "@/services/api";
import {
  mapAppointment,
  unwrapList,
  assertSuccess,
  slotsForDate,
} from "@/services/mappers";
import type { Appointment, DaySlots } from "@/types/domain";
import { doctorService } from "@/services/doctors";

type Raw = Record<string, unknown>;

function filterByStatus(list: Appointment[], status?: string): Appointment[] {
  if (!status) return list;
  const s = status.toLowerCase();
  if (s === "cancelled") return list.filter((a) => a.cancelled || a.status === "cancelled");
  if (s === "completed") return list.filter((a) => a.isCompleted || a.status === "completed");
  return list.filter(
    (a) => !a.cancelled && !a.isCompleted && a.status !== "cancelled" && a.status !== "completed"
  );
}

export const appointmentService = {
  async getMyAppointments(status?: string): Promise<Appointment[]> {
    const { data } = await api.get<Raw>("/api/user/appointments");
    assertSuccess(data);
    const list = unwrapList(data, ["appointments"]).map(mapAppointment);
    return filterByStatus(list, status);
  },

  async getById(id: string | number): Promise<Appointment> {
    const all = await this.getMyAppointments();
    const found = all.find((a) => String(a.id) === String(id));
    if (!found) throw new Error("Appointment not found");
    return found;
  },

  async create(body: {
    doctor_id: string | number;
    date: string;
    time: string;
    visit_type?: string;
    notes?: string;
    hospitalName?: string;
    location?: string;
  }) {
    const form = new FormData();
    form.append("docId", String(body.doctor_id));
    form.append("slotDate", body.date);
    form.append("slotTime", body.time);
    form.append(
      "symptoms",
      JSON.stringify(body.notes ? [body.notes] : [])
    );
    form.append("paymentMethod", "payOnVisit");
    if (body.hospitalName) form.append("hospitalName", body.hospitalName);
    if (body.location) form.append("location", body.location);

    const { data } = await api.post<Raw>("/api/user/book-appointment", form, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    assertSuccess(data, "Booking failed");
    return data;
  },

  cancel: (appointmentId: string | number) =>
    api.post<Raw>("/api/user/cancel-appointment", {
      appointmentId: Number(appointmentId),
    }),

  async getAvailableSlots(
    doctorId: string | number,
    slotDate: string
  ): Promise<DaySlots | null> {
    const { data } = await api.get<Raw>(`/api/ai/doctor-slots/${doctorId}`);
    assertSuccess(data);
    const doctor = await doctorService.getById(doctorId);
    const booked = doctor.slotsBooked?.[slotDate] ?? [];
    const availableSlots = (data.availableSlots ?? []) as Raw[];
    const slots = slotsForDate(availableSlots, slotDate, booked);

    const dayMeta = availableSlots.find((d) => d.date === slotDate) as Raw | undefined;

    return {
      date: slotDate,
      displayDate: String(dayMeta?.displayDate ?? slotDate),
      slots,
    };
  },
};
