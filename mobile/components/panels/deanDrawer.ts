import type { DrawerItem } from "@/components/panels/PanelShell";

export const DEAN_DRAWER: DrawerItem[] = [
  { label: "Dashboard", icon: "home-outline", href: "/(dean)/(tabs)/dashboard" },
  { label: "Students", icon: "school-outline", href: "/(dean)/(tabs)/students" },
  { label: "Faculty", icon: "people-outline", href: "/(dean)/(tabs)/faculty" },
  { label: "Departments", icon: "business-outline", href: "/(dean)/departments" },
  { label: "Approvals", icon: "checkmark-circle-outline", href: "/(dean)/approvals" },
  { label: "Reports", icon: "bar-chart-outline", href: "/(dean)/reports" },
  { label: "Calendar", icon: "calendar-outline", href: "/(dean)/calendar" },
  { label: "Notices", icon: "megaphone-outline", href: "/(dean)/notices" },
  { label: "Messages", icon: "chatbubbles-outline", href: "/(dean)/messages" },
  { label: "Profile", icon: "person-outline", href: "/(dean)/profile" },
  { label: "Settings", icon: "settings-outline", href: "/(dean)/settings" },
];
