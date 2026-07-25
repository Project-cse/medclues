import type { DrawerItem } from "@/components/panels/PanelShell";

export const ADMIN_DRAWER: DrawerItem[] = [
  { label: "Dashboard", icon: "home-outline", href: "/(admin)/(tabs)/dashboard" },
  { label: "Appointments", icon: "calendar-outline", href: "/(admin)/(tabs)/appointments" },
  { label: "Patients", icon: "people-outline", href: "/(admin)/(tabs)/patients" },
  { label: "Doctors", icon: "medkit-outline", href: "/(admin)/doctors" },
  { label: "Labs", icon: "flask-outline", href: "/(admin)/labs" },
  { label: "Reports", icon: "bar-chart-outline", href: "/(admin)/reports" },
  { label: "Users", icon: "person-circle-outline", href: "/(admin)/users" },
  { label: "Notifications", icon: "notifications-outline", href: "/(admin)/notifications" },
  { label: "Profile", icon: "person-outline", href: "/(admin)/profile" },
  { label: "Settings", icon: "settings-outline", href: "/(admin)/settings" },
];
