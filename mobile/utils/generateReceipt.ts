import * as Print from "expo-print";
import * as Sharing from "expo-sharing";

export type ReceiptAppointment = {
  id?: string;
  patient_name?: string;
  patient_id?: string;
  patient_phone?: string;
  patient_email?: string;
  doctor_name?: string;
  specialization?: string;
  hospital_name?: string;
  appointment_date?: string;
  appointment_time?: string;
  visit_type?: string;
  amount?: number;
  consultation_fee?: number;
  razorpay_payment_id?: string;
  razorpay_order_id?: string;
};

function esc(value: unknown): string {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function receiptHtml(appointment: ReceiptAppointment): string {
  const id = appointment.id ?? "—";
  const shortId = id.length > 8 ? id.slice(0, 8).toUpperCase() : id.toUpperCase();
  const amount = appointment.amount ?? appointment.consultation_fee ?? 0;
  const visit = appointment.visit_type ?? "in-clinic";
  const isOnline = visit.toLowerCase().includes("online");

  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; padding: 40px; color: #1E293B; }
    .header { text-align: center; border-bottom: 3px solid #0EA5E9; padding-bottom: 20px; margin-bottom: 30px; }
    .logo { font-size: 28px; font-weight: bold; color: #0EA5E9; }
    .receipt-title { font-size: 20px; color: #64748B; margin-top: 8px; }
    .receipt-id { font-size: 14px; color: #94A3B8; margin-top: 4px; }
    .section { margin-bottom: 25px; padding: 20px; background: #F8FAFC; border-radius: 12px; border-left: 4px solid #0EA5E9; }
    .section-title { font-size: 16px; font-weight: bold; color: #0EA5E9; margin-bottom: 12px; text-transform: uppercase; letter-spacing: 1px; }
    .row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 14px; }
    .label { color: #64748B; }
    .value { font-weight: 600; color: #1E293B; }
    .status-badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: bold; background: #DCFCE7; color: #16A34A; }
    .amount-section { background: #0EA5E9; color: white; padding: 20px; border-radius: 12px; text-align: center; margin: 20px 0; }
    .amount-value { font-size: 36px; font-weight: bold; margin-top: 4px; }
    .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #E2E8F0; color: #94A3B8; font-size: 12px; }
    .qr-note { text-align: center; padding: 15px; background: #F1F5F9; border-radius: 8px; margin: 15px 0; font-size: 13px; color: #64748B; }
  </style>
</head>
<body>
  <div class="header">
    <div class="logo">✚ MediChain+</div>
    <div class="receipt-title">Appointment Receipt</div>
    <div class="receipt-id">Receipt #${esc(shortId)}</div>
  </div>
  <div class="section">
    <div class="section-title">Patient Details</div>
    <div class="row"><span class="label">Patient Name</span><span class="value">${esc(appointment.patient_name)}</span></div>
    <div class="row"><span class="label">Phone</span><span class="value">${esc(appointment.patient_phone)}</span></div>
    <div class="row"><span class="label">Email</span><span class="value">${esc(appointment.patient_email)}</span></div>
  </div>
  <div class="section">
    <div class="section-title">Doctor Details</div>
    <div class="row"><span class="label">Doctor</span><span class="value">${esc(appointment.doctor_name)}</span></div>
    <div class="row"><span class="label">Specialization</span><span class="value">${esc(appointment.specialization)}</span></div>
    <div class="row"><span class="label">Hospital</span><span class="value">${esc(appointment.hospital_name ?? "MediChain+ Network")}</span></div>
  </div>
  <div class="section">
    <div class="section-title">Appointment Details</div>
    <div class="row"><span class="label">Date</span><span class="value">${esc(appointment.appointment_date)}</span></div>
    <div class="row"><span class="label">Time</span><span class="value">${esc(appointment.appointment_time)}</span></div>
    <div class="row"><span class="label">Visit Type</span><span class="value">${esc(visit)}</span></div>
    <div class="row"><span class="label">Status</span><span class="value"><span class="status-badge">✓ Confirmed</span></span></div>
  </div>
  <div class="amount-section">
    <div>Amount ${isOnline ? "Paid" : "Due"}</div>
    <div class="amount-value">₹${esc(amount)}</div>
    <div>${isOnline ? "💳 Paid via Razorpay" : "🏥 Pay at Clinic"}</div>
  </div>
  ${
    appointment.razorpay_payment_id
      ? `<div class="section">
    <div class="section-title">Payment Details</div>
    <div class="row"><span class="label">Payment ID</span><span class="value">${esc(appointment.razorpay_payment_id)}</span></div>
    <div class="row"><span class="label">Order ID</span><span class="value">${esc(appointment.razorpay_order_id)}</span></div>
  </div>`
      : ""
  }
  <div class="qr-note">📱 Show this receipt at the hospital reception</div>
  <div class="footer">
    <p>Thank you for choosing MediChain+</p>
    <p>Generated on: ${new Date().toLocaleString("en-IN")}</p>
  </div>
</body>
</html>`;
}

export async function generateReceipt(appointment: ReceiptAppointment): Promise<string> {
  const { uri } = await Print.printToFileAsync({
    html: receiptHtml(appointment),
    base64: false,
  });
  return uri;
}

export async function shareReceipt(pdfUri: string): Promise<void> {
  if (!(await Sharing.isAvailableAsync())) {
    throw new Error("Sharing is not available on this device");
  }
  await Sharing.shareAsync(pdfUri, {
    mimeType: "application/pdf",
    dialogTitle: "Download Appointment Receipt",
    UTI: "com.adobe.pdf",
  });
}
