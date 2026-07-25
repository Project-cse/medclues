import type { DrawerItem } from "@/components/panels/PanelShell";

export const DOCTOR_DRAWER: DrawerItem[] = [
  { label: "Dashboard", icon: "home-outline", href: "/(doctor)/(tabs)/dashboard" },
  { label: "Appointments", icon: "calendar-outline", href: "/(doctor)/(tabs)/appointments" },
  { label: "Patients", icon: "people-outline", href: "/(doctor)/(tabs)/patients" },
  { label: "Schedule", icon: "time-outline", href: "/(doctor)/schedule" },
  { label: "Prescription", icon: "medical-outline", href: "/(doctor)/new-prescription" },
  { label: "Medical Records", icon: "folder-outline", href: "/(doctor)/medical-records" },
  { label: "Reports", icon: "bar-chart-outline", href: "/(doctor)/(tabs)/reports" },
  { label: "Earnings", icon: "wallet-outline", href: "/(doctor)/earnings" },
  { label: "Notifications", icon: "notifications-outline", href: "/(doctor)/notifications" },
  { label: "Profile", icon: "person-outline", href: "/(doctor)/profile" },
  { label: "Settings", icon: "settings-outline", href: "/(doctor)/settings" },
];
