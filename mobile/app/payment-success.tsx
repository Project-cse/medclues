import { useLocalSearchParams } from "expo-router";
import { PaymentSuccess } from "@/src/screens/PaymentSuccess";

export default function PaymentSuccessRoute() {
  const params = useLocalSearchParams<{
    orderId?: string;
    paymentId?: string;
    amount?: string;
    appointmentId?: string;
  }>();

  return (
    <PaymentSuccess
      orderId={params.orderId ?? ""}
      paymentId={params.paymentId ?? ""}
      amount={params.amount ?? "0"}
      appointmentId={params.appointmentId}
    />
  );
}
