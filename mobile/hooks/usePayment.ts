import { useMutation } from "@tanstack/react-query";
import * as WebBrowser from "expo-web-browser";
import { paymentService } from "@/services/payment";
import { API_URL } from "@/constants/config";

export type PaymentRedirect = {
  razorpay_order_id: string;
  razorpay_payment_id: string;
  razorpay_signature: string;
  cancelled?: boolean;
  failed?: boolean;
};

export function parsePaymentRedirectUrl(url: string): PaymentRedirect | null {
  try {
    const query = url.includes("?") ? url.split("?")[1] : "";
    const params = new URLSearchParams(query);
    if (params.get("cancelled") === "1") {
      return { razorpay_order_id: "", razorpay_payment_id: "", razorpay_signature: "", cancelled: true };
    }
    if (params.get("failed") === "1") {
      return { razorpay_order_id: "", razorpay_payment_id: "", razorpay_signature: "", failed: true };
    }
    const razorpay_order_id = params.get("razorpay_order_id") ?? "";
    const razorpay_payment_id = params.get("razorpay_payment_id") ?? "";
    const razorpay_signature = params.get("razorpay_signature") ?? "";
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return null;
    }
    return { razorpay_order_id, razorpay_payment_id, razorpay_signature };
  } catch {
    return null;
  }
}

type InitiateParams = {
  doctorId: string;
  doctorName: string;
  consultationFee: number;
  appointmentDate: string;
  appointmentTime: string;
  notes?: string;
  onSuccess?: (appointmentId: string, amountInr: number, paymentIds?: PaymentRedirect) => void;
  onFailure?: (error: string) => void;
};

/** Expo-compatible Razorpay via hosted checkout + deep link (no native module). */
export function useRazorpayPayment() {
  const createOrderMutation = useMutation({
    mutationFn: paymentService.createOrder,
  });

  const verifyMutation = useMutation({
    mutationFn: paymentService.verifyPayment,
  });

  const initiatePayment = async ({
    doctorId,
    consultationFee,
    appointmentDate,
    appointmentTime,
    notes,
    onSuccess,
    onFailure,
  }: InitiateParams) => {
    let orderData: Awaited<ReturnType<typeof paymentService.createOrder>> | null = null;

    try {
      const fee = Number(consultationFee) || 500;
      orderData = await createOrderMutation.mutateAsync({
        amount: Math.round(fee * 100),
        doctor_id: String(doctorId),
        appointment_date: appointmentDate,
        appointment_time: appointmentTime,
        visit_type: "online",
        notes: notes ?? "",
      });

      if (!orderData.checkout_token) {
        onFailure?.("Payment checkout could not be started");
        return;
      }

      const checkoutUrl = `${API_URL}/api/payments/checkout?token=${encodeURIComponent(orderData.checkout_token)}`;

      const result = await WebBrowser.openAuthSessionAsync(checkoutUrl, "medichain://payment");

      if (result.type !== "success" || !result.url) {
        onFailure?.("Payment cancelled");
        return;
      }

      const redirect = parsePaymentRedirectUrl(result.url);
      if (!redirect) {
        onFailure?.("Payment was not completed");
        return;
      }
      if (redirect.cancelled) {
        onFailure?.("Payment cancelled");
        return;
      }
      if (redirect.failed) {
        onFailure?.("Payment failed. Try again.");
        return;
      }

      const verification = await verifyMutation.mutateAsync({
        razorpay_order_id: redirect.razorpay_order_id,
        razorpay_payment_id: redirect.razorpay_payment_id,
        razorpay_signature: redirect.razorpay_signature,
        appointment_id: orderData.appointment_id,
      });

      if (verification.success) {
        onSuccess?.(
          String(verification.appointment_id ?? orderData.appointment_id),
          fee,
          redirect
        );
      } else {
        onFailure?.("Payment verification failed. Contact support.");
      }
    } catch (error: unknown) {
      const err = error as { message?: string };
      const msg = err?.message ?? "Payment failed";

      if (orderData?.order_id) {
        try {
          await paymentService.failedPayment({
            order_id: orderData.order_id,
            appointment_id: orderData.appointment_id,
            error: msg,
          });
        } catch {
          /* ignore */
        }
      }

      onFailure?.(msg);
    }
  };

  return {
    initiatePayment,
    isLoading: createOrderMutation.isPending || verifyMutation.isPending,
  };
}
