import { ScrollView, View } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { ReportListItem } from "@/components/panels/ReportListItem";
import { fetchAdminReports } from "@/services/panels/adminPanel";
import { panelColors } from "@/constants/panelTheme";

export default function AdminReportsScreen() {
  const { data = [] } = useQuery({ queryKey: ["admin", "reports"], queryFn: fetchAdminReports });
  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Reports" />
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        {data.map((r) => <ReportListItem key={r.id} title={r.title} subtitle={r.subtitle} />)}
      </ScrollView>
    </View>
  );
}
