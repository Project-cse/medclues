import api from "@/services/api";
import {
  countRecordsByType,
  unwrapList,
  assertSuccess,
} from "@/services/mappers";
import type { RecordCounts } from "@/types/domain";

type Raw = Record<string, unknown>;

export const recordsService = {
  async getCounts(): Promise<RecordCounts> {
    const { data } = await api.get<Raw>("/api/user/health-records");
    if (data.success === false) {
      return {
        prescriptions: 0,
        labReports: 0,
        medicalHistory: 0,
        vaccinations: 0,
        allergies: 0,
        vitals: 0,
      };
    }
    const records = unwrapList(data, ["records", "healthRecords"]).map((r) => ({
      recordType: String((r as Raw).recordType ?? (r as Raw).record_type ?? ""),
    }));
    return countRecordsByType(records);
  },

  getPrescriptions: () => api.get("/api/user/health-records", { params: { recordType: "prescription" } }),
  getLabReports: () => api.get("/api/user/health-records", { params: { recordType: "lab" } }),
  getMedicalHistory: () => api.get("/api/user/health-records"),
  getVaccinations: () => api.get("/api/user/health-records", { params: { recordType: "vaccination" } }),
  getAllergies: () => api.get("/api/user/health-records", { params: { recordType: "allergy" } }),
  getVitals: () => api.get("/api/user/health-records", { params: { recordType: "vitals" } }),
};
