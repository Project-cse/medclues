import apiClient from "@/src/api/apiClient";

export async function sendForgotPasswordOtp(email: string, role: string) {
  const { data } = await apiClient.post<{
    success?: boolean;
    message?: string;
    dev_otp?: string;
  }>("/api/auth/forgot-password", {
    email: email.trim().toLowerCase(),
    role,
  });
    if (data.success === false) {
      throw new Error(data.message ?? "Failed to send OTP");
    }
    return {
      ...data,
      dev_otp: data.dev_otp as string | undefined,
    };
}

export async function verifyOtp(email: string, otp: string, role: string) {
  const { data } = await apiClient.post<{ valid?: boolean }>("/api/auth/verify-otp", {
    email: email.trim().toLowerCase(),
    otp,
    role,
  });
  return data;
}

export async function resetPassword(
  email: string,
  otp: string,
  newPassword: string,
  role: string
) {
  const { data } = await apiClient.post<{ message?: string }>("/api/auth/reset-password", {
    email: email.trim().toLowerCase(),
    otp,
    new_password: newPassword,
    role,
  });
  return data;
}
