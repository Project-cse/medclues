import axios from "axios";
import { createContext, useEffect, useState } from "react";
import { toast } from "react-toastify";

export const DeanContext = createContext();

const DeanContextProvider = ({ children }) => {
  const backendUrl = import.meta.env.VITE_BACKEND_URL;

  const [deanToken, setDeanToken] = useState(
    sessionStorage.getItem("deanToken") || ""
  );
  const [deanInfo, setDeanInfo] = useState(
    sessionStorage.getItem("deanInfo")
      ? JSON.parse(sessionStorage.getItem("deanInfo"))
      : null
  );

  useEffect(() => {
    const onRefresh = (e) => {
      if (e.detail?.role === "dean" && e.detail.token) setDeanToken(e.detail.token);
    };
    const onLogout = (e) => {
      if (e.detail?.role === "dean") {
        setDeanToken("");
        setDeanInfo(null);
      }
    };
    window.addEventListener("auth:tokenRefreshed", onRefresh);
    window.addEventListener("auth:logout", onLogout);
    return () => {
      window.removeEventListener("auth:tokenRefreshed", onRefresh);
      window.removeEventListener("auth:logout", onLogout);
    };
  }, []);

  const [dashData, setDashData] = useState(null);
  const [doctors, setDoctors] = useState([]);
  const [appointments, setAppointments] = useState([]);
  const [hospital, setHospital] = useState(null);
  const [revenueData, setRevenueData] = useState(null);

  const authHeader = { deantoken: deanToken };

  // ── Dashboard ──────────────────────────────────────────────────────────────
  const getDashData = async () => {
    try {
      const { data } = await axios.get(`${backendUrl}/api/dean/dashboard`, {
        headers: authHeader,
      });
      if (data.success) {
        setDashData(data.dashData);
      } else {
        toast.error(data.message);
      }
    } catch (err) {
      toast.error(err.message);
    }
  };

  // ── Hospital ───────────────────────────────────────────────────────────────
  const getHospital = async () => {
    try {
      const { data } = await axios.get(`${backendUrl}/api/dean/hospital`, {
        headers: authHeader,
      });
      if (data.success) setHospital(data.hospital);
      else toast.error(data.message);
    } catch (err) {
      toast.error(err.message);
    }
  };

  const updateHospital = async (hospitalData) => {
    try {
      const { data } = await axios.put(
        `${backendUrl}/api/dean/hospital/update`,
        hospitalData,
        { headers: authHeader }
      );
      if (data.success) {
        toast.success(data.message);
        await getHospital();
        return true;
      } else {
        toast.error(data.message);
        return false;
      }
    } catch (err) {
      toast.error(err.message);
      return false;
    }
  };

  // ── Doctors ────────────────────────────────────────────────────────────────
  const getDoctors = async () => {
    try {
      const { data } = await axios.get(`${backendUrl}/api/dean/doctors`, {
        headers: authHeader,
      });
      if (data.success) setDoctors(data.doctors);
      else toast.error(data.message);
    } catch (err) {
      toast.error(err.message);
    }
  };

  const addDoctor = async (doctorData) => {
    try {
      const { data } = await axios.post(
        `${backendUrl}/api/dean/doctors/add`,
        doctorData,
        { headers: authHeader }
      );
      if (data.success) {
        toast.success(data.message);
        await getDoctors();
        return true;
      } else {
        toast.error(data.message);
        return false;
      }
    } catch (err) {
      toast.error(err.message);
      return false;
    }
  };

  const changeAvailability = async (doctorId) => {
    try {
      const { data } = await axios.post(
        `${backendUrl}/api/dean/doctors/availability`,
        { doctorId },
        { headers: authHeader }
      );
      if (data.success) {
        toast.success(data.message);
        await getDoctors();
      } else {
        toast.error(data.message);
      }
    } catch (err) {
      toast.error(err.message);
    }
  };

  // ── Appointments ───────────────────────────────────────────────────────────
  const getAllAppointments = async () => {
    try {
      const { data } = await axios.get(`${backendUrl}/api/dean/appointments`, {
        headers: authHeader,
      });
      if (data.success) setAppointments(data.appointments);
      else toast.error(data.message);
    } catch (err) {
      toast.error(err.message);
    }
  };

  const cancelAppointment = async (appointmentId) => {
    try {
      const { data } = await axios.post(
        `${backendUrl}/api/dean/appointments/cancel`,
        { appointmentId },
        { headers: authHeader }
      );
      if (data.success) {
        toast.success(data.message);
        await getAllAppointments();
      } else {
        toast.error(data.message);
      }
    } catch (err) {
      toast.error(err.message);
    }
  };

  const getRevenueAnalytics = async () => {
    try {
      const { data } = await axios.get(`${backendUrl}/api/dean/revenue-analytics`, {
        headers: authHeader,
      });
      if (data.success) {
        setRevenueData(data.analytics);
        return data.analytics;
      } else {
        toast.error(data.message);
      }
    } catch (err) {
      toast.error(err.message);
    }
  };

  // ── Logout ─────────────────────────────────────────────────────────────────
  const logout = () => {
    setDeanToken("");
    setDeanInfo(null);
    sessionStorage.removeItem("deanToken");
    sessionStorage.removeItem("deanInfo");
  };

  const deleteDoctor = async (doctorId) => {
    try {
      const { data } = await axios.post(
        `${backendUrl}/api/dean/doctors/delete`,
        { doctorId },
        { headers: authHeader }
      );
      if (data.success) {
        toast.success(data.message);
        await getDoctors();
        return true;
      } else {
        toast.error(data.message);
        return false;
      }
    } catch (err) {
      toast.error(err.message);
      return false;
    }
  };

  const updateDoctor = async (doctorId, doctorData) => {
    try {
      const { data } = await axios.put(
        `${backendUrl}/api/dean/doctors/update`,
        { doctorId, doctorData },
        { headers: authHeader }
      );
      if (data.success) {
        toast.success(data.message);
        await getDoctors();
        return true;
      } else {
        toast.error(data.message);
        return false;
      }
    } catch (err) {
      toast.error(err.message);
      return false;
    }
  };

  const toggleStatus = async (doctorId) => {
    try {
      const { data } = await axios.post(
        `${backendUrl}/api/dean/doctors/toggle-status`,
        { doctorId },
        { headers: authHeader }
      );
      if (data.success) {
        toast.success(data.message);
        await getDoctors();
      } else {
        toast.error(data.message);
      }
    } catch (err) {
      toast.error(err.message);
    }
  };

  const resetPassword = async (doctorId, newPassword) => {
    try {
      const { data } = await axios.post(
        `${backendUrl}/api/dean/doctors/reset-password`,
        { doctorId, newPassword },
        { headers: authHeader }
      );
      if (data.success) {
        toast.success(data.message);
        return true;
      } else {
        toast.error(data.message);
        return false;
      }
    } catch (err) {
      toast.error(err.message);
      return false;
    }
  };

  const value = {
    deanToken,
    setDeanToken,
    deanInfo,
    setDeanInfo,
    dashData,
    getDashData,
    hospital,
    getHospital,
    updateHospital,
    doctors,
    getDoctors,
    addDoctor,
    updateDoctor,
    deleteDoctor,
    changeAvailability,
    toggleStatus,
    resetPassword,
    appointments,
    getAllAppointments,
    cancelAppointment,
    revenueData,
    getRevenueAnalytics,
    logout,
  };

  return <DeanContext.Provider value={value}>{children}</DeanContext.Provider>;
};

export default DeanContextProvider;
