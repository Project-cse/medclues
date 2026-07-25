import api from "@/services/api";

export type CreateOrderPayload = {
  amount: number;
  doctor_id: string;
  appointment_date: string;
  appointment_time: string;
  visit_type: string;
  notes?: string;
};

export type CreateOrderResponse = {
  success?: boolean;
  order_id: string;
  amount: number;
  currency: string;
  razorpay_key: string;
  doctor_name?: string;
  appointment_id: string;
  checkout_token?: string;
  message?: string;
};

export type VerifyPaymentPayload = {
  razorpay_order_id: string;
  razorpay_payment_id: string;
  razorpay_signature: string;
  appointment_id: string;
};

export const paymentService = {
  createOrder: async (data: CreateOrderPayload) => {
    const { data: res } = await api.post<CreateOrderResponse>("/api/payments/create-order", data);
    if (!res.order_id || !res.razorpay_key || !res.checkout_token) {
      throw new Error(res.message ?? "Failed to create payment order");
    }
    return res;
  },

  verifyPayment: async (data: VerifyPaymentPayload) => {
    const { data: res } = await api.post<{
      success: boolean;
      appointment_id?: string;
      message?: string;
    }>("/api/payments/verify", data);
    if (!res.success) {
      throw new Error(res.message ?? "Payment verification failed");
    }
    return res;
  },

  failedPayment: (data: { order_id: string; appointment_id: string; error: string }) =>
    api.post("/api/payments/failed", data).then((r) => r.data),

  getPaymentHistory: () =>
    api.get<{ success: boolean; payments: PaymentHistoryItem[] }>("/api/payments/history").then(
      (r) => r.data.payments ?? []
    ),
};

export type PaymentHistoryItem = {
  id: string;
  order_id?: string;
  payment_id?: string;
  appointment_id?: string;
  doctor_name?: string;
  amount_inr?: number;
  amount_paise?: number;
  status: "paid" | "failed" | "refunded" | string;
  error?: string;
  created_at?: string;
};
