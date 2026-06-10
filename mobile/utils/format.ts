/** Format slot_date from API (DD_MM_YYYY) for display */
export function formatSlotDate(slotDate: string): string {
  if (!slotDate) return "";
  const parts = slotDate.split("_");
  if (parts.length !== 3) return slotDate;
  const [d, m, y] = parts.map(Number);
  const date = new Date(y, m - 1, d);
  if (Number.isNaN(date.getTime())) return slotDate;
  return date.toLocaleDateString("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

export function formatInr(amount?: number): string {
  if (amount == null) return "";
  return `₹${amount.toLocaleString("en-IN")}`;
}

export function slotDateFromDate(d: Date): string {
  const day = d.getDate().toString().padStart(2, "0");
  const month = (d.getMonth() + 1).toString().padStart(2, "0");
  const year = d.getFullYear();
  return `${day}_${month}_${year}`;
}

export function buildNext7Days(): {
  label: string;
  date: Date;
  dayNum: number;
  slotDate: string;
}[] {
  const out: { label: string; date: Date; dayNum: number; slotDate: string }[] = [];
  const today = new Date();
  const labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  for (let i = 0; i < 7; i++) {
    const d = new Date(today);
    d.setDate(today.getDate() + i);
    out.push({
      label: i === 0 ? "Today" : labels[d.getDay()],
      date: d,
      dayNum: d.getDate(),
      slotDate: slotDateFromDate(d),
    });
  }
  return out;
}
