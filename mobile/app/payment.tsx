import { useLocalSearchParams } from "expo-router";
import { PaymentScreen } from "@/src/screens/PaymentScreen";

export default function PaymentRoute() {
  const params = useLocalSearchParams<{
    amount?: string;
    patientName?: string;
    email?: string;
    contact?: string;
    appointmentId?: string;
  }>();

  const amount = parseFloat(params.amount ?? "0") || 0;

  return (
    <PaymentScreen
      amount={amount}
      patientName={params.patientName ?? "Patient"}
      email={params.email ?? ""}
      contact={params.contact ?? ""}
      appointmentId={params.appointmentId}
    />
  );
}
