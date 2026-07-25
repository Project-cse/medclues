import apiClient from "@/src/api/apiClient";

export async function getRazorpayKey(): Promise<{ key_id: string }> {
  const { data } = await apiClient.get<{ key_id?: string; success?: boolean; message?: string }>(
    "/api/payments/razorpay-key"
  );
  const key = data.key_id;
  if (!key) {
    throw new Error(data.message ?? "Razorpay key not available");
  }
  return { key_id: key };
}

export async function createOrder(amountInr: number) {
  const { data } = await apiClient.post<{
    success?: boolean;
    order_id?: string;
    amount?: number;
    currency?: string;
    checkout_token?: string;
    message?: string;
  }>("/api/payments/create-order", {
    amount: Math.round(amountInr * 100),
    currency: "INR",
  });
  if (!data.order_id || !data.checkout_token) {
    throw new Error(data.message ?? "Failed to create payment order");
  }
  return {
    order_id: data.order_id,
    amount: data.amount ?? Math.round(amountInr * 100),
    currency: data.currency ?? "INR",
    checkout_token: data.checkout_token,
  };
}

export async function verifyPayment(payload: {
  razorpay_order_id: string;
  razorpay_payment_id: string;
  razorpay_signature: string;
}) {
  const { data } = await apiClient.post<{ success: boolean; message?: string }>(
    "/api/payments/verify-signature",
    payload
  );
  if (!data.success) {
    throw new Error(data.message ?? "Payment verification failed");
  }
  return { success: true as const };
}
