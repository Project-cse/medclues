import { PageHeader } from "@/components/PageHeader";
import { PlaceholderList } from "@/components/PlaceholderList";
import { Screen } from "@/components/Screen";

export default function BillingScreen() {
  return (
    <Screen>
      <PageHeader title="Billing" subtitle="Payments & invoices" />
      <PlaceholderList
        title="Billing module"
        description="Integrate Razorpay and appointment payment status from your existing backend when you are ready."
      />
    </Screen>
  );
}
