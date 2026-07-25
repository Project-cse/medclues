import { PageHeader } from "@/components/PageHeader";
import { PlaceholderList } from "@/components/PlaceholderList";
import { Screen } from "@/components/Screen";

export default function ScheduleScreen() {
  return (
    <Screen>
      <PageHeader title="Schedule" subtitle="Availability & time slots" />
      <PlaceholderList
        title="Schedule module"
        description="Connect to doctor availability endpoints such as /api/doctor/change-availability and your slot management APIs."
      />
    </Screen>
  );
}
