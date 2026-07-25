export type AuthThemeKey = "blue" | "red";

export function getAuthTheme(theme: AuthThemeKey) {
  if (theme === "red") {
    return {
      primary: "#C0392B",
      primaryDark: "#922B21",
      primaryLight: "#FADBD8",
      gradient: ["#922B21", "#C0392B"] as [string, string],
      accent: "#C0392B",
    };
  }
  return {
    primary: "#1A56DB",
    primaryDark: "#0D47A1",
    primaryLight: "#E3F2FD",
    gradient: ["#0D47A1", "#1A56DB"] as [string, string],
    accent: "#1A56DB",
  };
}

export function loginPathForTheme(theme: AuthThemeKey): string {
  return theme === "red" ? "/(auth)/login-staff" : "/(auth)/login-patient";
}

export function maskEmail(email: string): string {
  const trimmed = email.trim();
  const at = trimmed.indexOf("@");
  if (at <= 1) return trimmed;
  const local = trimmed.slice(0, at);
  const domain = trimmed.slice(at);
  const visible = local.slice(0, 2);
  return `${visible}${"*".repeat(Math.max(local.length - 2, 2))}${domain}`;
}

export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}
