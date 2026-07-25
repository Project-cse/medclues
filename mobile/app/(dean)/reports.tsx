import { ScrollView } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { ScreenHeader } from "@/components/ui/ScreenHeader";
import { ReportListItem } from "@/components/panels/ReportListItem";
import { fetchDeanReports } from "@/services/panels/deanPanel";
import { panelColors } from "@/constants/panelTheme";
import { View } from "react-native";

export default function DeanReportsScreen() {
  const { data = [] } = useQuery({ queryKey: ["dean", "reports"], queryFn: fetchDeanReports });
  return (
    <View style={{ flex: 1, backgroundColor: panelColors.background }}>
      <ScreenHeader title="Reports" />
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        {data.map((r) => <ReportListItem key={r.id} title={r.title} subtitle={r.subtitle} />)}
      </ScrollView>
    </View>
  );
}
