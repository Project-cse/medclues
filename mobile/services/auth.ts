import api from "@/services/api";
import { mapUser, assertSuccess } from "@/services/mappers";
import type { UserProfile } from "@/types/domain";
import type { User, UserRole } from "@/types/api";
import { useAuthStore } from "@/store/authStore";

type Raw = Record<string, unknown>;

export const authService = {
  async loginPatient(email: string, password: string) {
    const { data } = await api.post<Raw>("/api/user/login", { email, password });
    assertSuccess(data, "Invalid credentials");
    if (!data.token) throw new Error("No token returned");
    return String(data.token);
  },

  async loginAdmin(email: string, password: string) {
    const { data } = await api.post<Raw>("/api/admin/login", {
      email: email.trim().toLowerCase(),
      password: password.trim(),
    });
    assertSuccess(data, "Invalid credentials");
    if (!data.token) throw new Error("No token returned");
    return String(data.token);
  },

  register: (body: {
    name: string;
    email: string;
    phone: string;
    password: string;
    gender?: string;
    dob?: string;
  }) => api.post<Raw>("/api/user/register", body),

  async getMe(): Promise<UserProfile> {
    const { data } = await api.get<Raw>("/api/user/get-profile");
    assertSuccess(data);
    const user = (data.userData ?? data.user) as Raw | null | undefined;
    if (!user || typeof user !== "object") {
      throw new Error("Profile data unavailable");
    }
    return mapUser(user);
  },

  async patchProfile(body: Record<string, unknown>) {
    const clean = Object.fromEntries(
      Object.entries(body).filter(([, v]) => v !== null && v !== undefined && v !== "")
    );
    const { data } = await api.patch<Raw>("/api/user/profile", clean);
    assertSuccess(data, "Update failed");
    const user = (data.userData ?? data.user) as Raw | undefined;
    return user ? mapUser(user) : null;
  },

  uploadProfilePic: async (uri: string) => {
    const form = new FormData();
    form.append("image", {
      uri,
      name: "profile_photo.jpg",
      type: "image/jpeg",
    } as unknown as Blob);
    const { data } = await api.post<Raw>("/api/user/update-profile", form, {
      headers: { "Content-Type": "multipart/form-data" },
      timeout: 30000,
    });
    assertSuccess(data, "Upload failed");
    const pic =
      (data.profile_pic_url as string | undefined) ??
      ((data.userData as Raw | undefined)?.image as string | undefined);
    return { data, profilePicUrl: pic };
  },

  forgotPassword: (email: string) =>
    api.post<Raw>("/api/user/forgot-password", { email }),
};

export async function loginWithRole(payload: {
  email: string;
  password: string;
  role: UserRole;
}): Promise<{ token: string; user: User }> {
  const { email, password, role } = payload;
  let token: string;

  if (role === "patient") {
    token = await authService.loginPatient(email.trim(), password);
  } else if (role === "admin") {
    token = await authService.loginAdmin(email.trim(), password);
  } else {
    const path =
      role === "doctor"
        ? "/api/doctor/login"
        : role === "dean"
          ? "/api/dean/login"
          : "/api/user/login";
    const { data } = await api.post<Raw>(path, { email: email.trim(), password });
    assertSuccess(data);
    if (!data.token) throw new Error("Invalid credentials");
    token = String(data.token);
  }

  await useAuthStore.getState().setAuth(token, {
    id: email,
    name: email.split("@")[0],
    email: email.trim(),
    role,
    branch_id: null,
  });

  if (role === "patient") {
    const me = await authService.getMe();
    const user: User = {
      id: me.id,
      name: me.name,
      email: me.email ?? email,
      role: "patient",
      branch_id: null,
      phone: me.phone,
      image: me.profilePicUrl,
    };
    await useAuthStore.getState().setAuth(token, user);
    return { token, user };
  }

  const user = useAuthStore.getState().user!;
  return { token, user };
}

export async function logout(): Promise<void> {
  await useAuthStore.getState().clearAuth();
}
