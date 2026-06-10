import { PageHeader } from "@/components/PageHeader";
import { PlaceholderList } from "@/components/PlaceholderList";
import { Screen } from "@/components/Screen";

export default function PatientsScreen() {
  return (
    <Screen>
      <PageHeader
        title="Patients"
        subtitle="Patient list from your FastAPI backend"
      />
      <PlaceholderList
        title="Coming soon"
        description="Wire this screen to /api/dean/patients or your preferred patient endpoint. The API client, auth headers, and React Query setup are ready."
      />
    </Screen>
  );
}
