import { ScrollView } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { PanelShell } from "@/components/panels/PanelShell";
import { DOCTOR_DRAWER } from "@/components/panels/doctorDrawer";
import { ReportListItem } from "@/components/panels/ReportListItem";
import { fetchDoctorReports } from "@/services/panels/doctorPanel";
import { useAuth } from "@/hooks/useAuth";
import { panelColors } from "@/constants/panelTheme";

export default function DoctorReportsTab() {
  const { user } = useAuth();
  const { data } = useQuery({ queryKey: ["doctor", "reports"], queryFn: fetchDoctorReports });

  const items = data
    ? [
        { title: "Prescription Reports", subtitle: `${data.prescriptions} reports`, icon: "medical-outline" as const },
        { title: "Appointment Reports", subtitle: `${data.appointments} reports`, icon: "calendar-outline" as const },
        { title: "Patient Reports", subtitle: `${data.patients} reports`, icon: "people-outline" as const },
        { title: "Revenue Reports", subtitle: `₹${data.revenue}`, icon: "wallet-outline" as const, color: panelColors.accent },
        { title: "Diagnosis Reports", subtitle: `${data.diagnosis} reports`, icon: "pulse-outline" as const },
        { title: "Visit Summary", subtitle: `${data.visits} reports`, icon: "document-text-outline" as const },
      ]
    : [];

  return (
    <PanelShell title="Reports" drawerHeader={{ name: user?.name ?? "Doctor", subtitle: "Reports" }} drawerItems={DOCTOR_DRAWER}>
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 80 }}>
        {items.map((item) => (
          <ReportListItem key={item.title} title={item.title} subtitle={item.subtitle} icon={item.icon} iconColor={item.color ?? panelColors.primary} />
        ))}
      </ScrollView>
    </PanelShell>
  );
}
