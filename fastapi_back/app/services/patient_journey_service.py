"""Patient Journey Agent + Orchestrator.

Deterministic coordination state is computed from existing MEDCLUES tables.
The configured LLM is used only to phrase a grounded summary — never to diagnose.
"""
from __future__ import annotations

import asyncio
import json
import time
from datetime import date, datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple
from zoneinfo import ZoneInfo

from app.models import (
    appointment_model,
    doctor_model,
    followup_model,
    investigation_model,
    notification_model,
    order_event_model,
    order_finding_model,
    pharmacy_order_model,
    referral_model,
    user_model,
)
from app.utils.app_logger import get_logger

log = get_logger("medclues.patient_journey")

# Patient self-service history limits
PATIENT_APPOINTMENT_LIMIT = 50
PAST_EPISODES_MAX = 50

# Short TTL cache for patient self-service journey (avoids repeated Neon round-trips).
_PATIENT_JOURNEY_CACHE: Dict[int, Tuple[float, Dict[str, Any]]] = {}
_PATIENT_JOURNEY_TTL_SEC = 120.0
# Staff dashboards share the pool; patient self-service uses direct parallel reads.
_JOURNEY_DB_SEM = asyncio.Semaphore(2)


async def _limited_db(awaitable):
    async with _JOURNEY_DB_SEM:
        return await awaitable


def invalidate_patient_journey_cache(patient_id: int) -> None:
    _PATIENT_JOURNEY_CACHE.pop(int(patient_id), None)


async def _safe_care_decision(patient_id: int) -> Dict[str, Any]:
    try:
        from app.models import care_decision_model
        return await care_decision_model.get_for_patient(patient_id) or {}
    except Exception:
        return {}


async def _safe_patient_notifications(patient_id: int) -> List[Dict[str, Any]]:
    try:
        return await notification_model.list_for_user(patient_id, limit=8)
    except Exception as e:
        log.warning("patient notifications skipped: %s", e)
        return []
IST = ZoneInfo("Asia/Kolkata")

PRIORITY_RANK = {"HIGH": 3, "MEDIUM": 2, "LOW": 1}


def _today() -> date:
    return datetime.now(IST).date()


def _iso(val: Any) -> Optional[str]:
    if val is None:
        return None
    if hasattr(val, "isoformat"):
        return val.isoformat()
    return str(val)


def _as_date(val: Any) -> Optional[date]:
    if val is None:
        return None
    if isinstance(val, datetime):
        return val.date()
    if isinstance(val, date):
        return val
    if isinstance(val, str):
        try:
            return date.fromisoformat(val[:10])
        except ValueError:
            return None
    return None


def _latest(rows: List[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
    return rows[0] if rows else None


# Fully closed — only these belong in history once a newer visit exists.
HISTORY_ONLY_LIFECYCLES = frozenset({
    "CLOSED",
    "CANCELLED",
    "EXPIRED",
    "REFUNDED",
    "REFUND_PENDING",
    "FOLLOWUP_EXPIRED",
})

# Current-visit lifecycles (including missed — patient may still reschedule).
CURRENT_EPISODE_LIFECYCLES = frozenset({
    "BOOKED",
    "CONFIRMED",
    "CHECKED_IN",
    "IN_QUEUE",
    "IN_PROGRESS",
    "COMPLETED",
    "FOLLOWUP_AVAILABLE",
    "RESCHEDULED_ONCE",
    "READY_FOR_DOCTOR",
    "MISSED",
    "NO_SHOW",
})

# Kept for staff/coordination helpers that treat missed as closed.
TERMINAL_APPOINTMENT_LIFECYCLES = HISTORY_ONLY_LIFECYCLES | frozenset({"MISSED", "NO_SHOW"})


def _as_datetime(val: Any) -> Optional[datetime]:
    if val is None:
        return None
    if isinstance(val, datetime):
        return val if val.tzinfo else val.replace(tzinfo=IST)
    if isinstance(val, str):
        try:
            return datetime.fromisoformat(val.replace("Z", "+00:00"))
        except ValueError:
            return None
    return None


def _is_terminal_appointment(appt: Optional[Dict[str, Any]]) -> bool:
    """True when appointment belongs in history, not the live care journey."""
    if not appt:
        return True
    if appt.get("cancelled"):
        return True
    life = str(appt.get("lifecycle_status") or "").strip().upper()
    if life in CURRENT_EPISODE_LIFECYCLES:
        return False
    if life in HISTORY_ONLY_LIFECYCLES:
        return True
    if not life:
        status = str(appt.get("status") or "").strip().upper()
        if status in HISTORY_ONLY_LIFECYCLES or status == "CANCELLED":
            return True
        if status in {"MISSED", "NO-SHOW", "NO_SHOW", "PENDING", "CONFIRMED", "COMPLETED"}:
            return False
    return False


def _pick_active_appointment(appointments: List[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
    for row in appointments or []:
        appt = dict(row)
        if not _is_terminal_appointment(appt):
            return appt
    return None


def _filter_episode_rows(
    rows: List[Any],
    start_ts: Any,
    end_ts: Any = None,
) -> List[Dict[str, Any]]:
    start = _as_datetime(start_ts)
    end = _as_datetime(end_ts) if end_ts is not None else None
    if not start:
        return [dict(r) for r in (rows or [])]
    out: List[Dict[str, Any]] = []
    for row in rows or []:
        r = dict(row)
        created = _as_datetime(r.get("created_at"))
        if created is None or created < start:
            continue
        if end is not None and created >= end:
            continue
        out.append(r)
    return out


def _filter_episode_notifications(
    notes: List[Any],
    start_ts: Any,
    end_ts: Any = None,
    *,
    appointment_id: Optional[int] = None,
) -> List[Dict[str, Any]]:
    start = _as_datetime(start_ts)
    end = _as_datetime(end_ts) if end_ts is not None else None
    out: List[Dict[str, Any]] = []
    for row in notes or []:
        n = dict(row)
        if appointment_id is not None and n.get("appointment_id") is not None:
            if int(n["appointment_id"]) != int(appointment_id):
                continue
        created = _as_datetime(n.get("created_at"))
        if start and created and created < start:
            continue
        if end and created and created >= end:
            continue
        out.append(n)
    return out


def _care_decision_for_episode(decision: Dict[str, Any], episode_start: Any) -> Dict[str, Any]:
    if not decision:
        return {}
    start = _as_datetime(episode_start)
    updated = _as_datetime(decision.get("updated_at"))
    if start and updated and updated < start:
        return {}
    return decision


def _parse_doc_data(appt: Optional[Dict[str, Any]]) -> Dict[str, Any]:
    if not appt:
        return {}
    doc = appt.get("docData") or appt.get("doc_data") or appt.get("doctor_data") or {}
    if isinstance(doc, str):
        try:
            doc = json.loads(doc)
        except (json.JSONDecodeError, TypeError):
            doc = {}
    return doc if isinstance(doc, dict) else {}


def _normalize_doctor_name(name: Optional[str]) -> Optional[str]:
    if not name:
        return None
    s = str(name).strip()
    lower = s.lower()
    if lower.startswith("dr."):
        s = s[3:].strip()
    elif lower.startswith("dr "):
        s = s[2:].strip()
    return s or None


def _format_doctor_display(name: Optional[str]) -> Optional[str]:
    base = _normalize_doctor_name(name)
    return f"Dr. {base}" if base else None


def _appt_doctor_name(appt: Optional[Dict[str, Any]]) -> Optional[str]:
    doc = _parse_doc_data(appt)
    name = doc.get("name") or (appt or {}).get("doctor_name")
    return _normalize_doctor_name(name)


def _appt_slot_date(appt: Optional[Dict[str, Any]]) -> Optional[str]:
    if not appt:
        return None
    return appt.get("slotDate") or appt.get("slot_date")


def _episode_label(appt: Dict[str, Any]) -> str:
    doctor = _appt_doctor_name(appt)
    slot = _appt_slot_date(appt)
    if slot:
        parts = str(slot).split("_")
        if len(parts) == 3:
            d, m, y = parts
            try:
                date_str = date(int(y), int(m), int(d)).strftime("%d %b %Y")
            except ValueError:
                date_str = slot.replace("_", "/")
        else:
            date_str = slot.replace("_", "/")
    else:
        date_str = _format_display_date(appt.get("created_at")) or "Visit"
    if doctor:
        return f"{date_str} · {_format_doctor_display(doctor)}"
    return date_str


def _patient_journey_status_label(journey_status: str) -> str:
    js = str(journey_status or "").upper()
    if js == "ON_TRACK":
        return "ON_TRACK"
    if js == "UPCOMING":
        return "UPCOMING"
    if js == "OVERDUE":
        return "OVERDUE"
    return "ACTION_NEEDED"


def _episode_bounds_for_appt(
    appointments_list: List[Dict[str, Any]],
    appt: Optional[Dict[str, Any]],
) -> tuple[Any, Any]:
    if not appt:
        return None, None
    idx = next(
        (i for i, row in enumerate(appointments_list) if row.get("id") == appt.get("id")),
        None,
    )
    if idx is None:
        return appt.get("created_at"), None
    start = appointments_list[idx].get("created_at")
    end = appointments_list[idx - 1].get("created_at") if idx > 0 else None
    return start, end


def _filter_findings_to_episode(
    findings: List[Dict[str, Any]],
    *,
    investigations: List[Dict[str, Any]],
    referrals: List[Dict[str, Any]],
    followups: List[Dict[str, Any]],
    pharm_orders: List[Dict[str, Any]],
    appt: Optional[Dict[str, Any]],
) -> List[Dict[str, Any]]:
    inv_ids = {int(x["id"]) for x in investigations if x.get("id") is not None}
    ref_ids = {int(x["id"]) for x in referrals if x.get("id") is not None}
    fol_ids = {int(x["id"]) for x in followups if x.get("id") is not None}
    pharm_ids = {int(x["id"]) for x in pharm_orders if x.get("id") is not None}
    apt_id = int(appt["id"]) if appt and appt.get("id") is not None else None
    spec_appt_ids = {
        int(x["specialist_appointment_id"])
        for x in referrals
        if x.get("specialist_appointment_id") is not None
    }
    out: List[Dict[str, Any]] = []
    for f in findings or []:
        et = str(f.get("entity_type") or "").lower()
        eid = f.get("entity_id")
        if eid is None:
            continue
        try:
            eid_int = int(eid)
        except (TypeError, ValueError):
            continue
        if et == "investigation" and eid_int in inv_ids:
            out.append(f)
        elif et == "referral" and eid_int in ref_ids:
            out.append(f)
        elif et == "followup" and eid_int in fol_ids:
            out.append(f)
        elif et in {"pharmacy", "pharmacy_order"} and eid_int in pharm_ids:
            out.append(f)
        elif et == "appointment" and (
            (apt_id is not None and eid_int == apt_id) or eid_int in spec_appt_ids
        ):
            out.append(f)
    return out


def _episode_report_rows(investigations: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """One report per test name for the current episode (latest first)."""
    reports: List[Dict[str, Any]] = []
    seen: set[str] = set()
    for row in investigations or []:
        r = dict(row)
        st = str(r.get("status") or "").upper()
        if not (r.get("report_url") or st in {"REPORT_AVAILABLE", "REVIEWED"}):
            continue
        key = str(r.get("test_name") or "").strip().lower() or f"id:{r.get('id')}"
        if key in seen:
            continue
        seen.add(key)
        reports.append({
            "id": r.get("id"),
            "test_name": r.get("test_name"),
            "status": r.get("status"),
            "report_url": r.get("report_url"),
            "report_review_status": r.get("report_review_status"),
            "report_access_path": f"/api/investigations/{r.get('id')}/report",
        })
    return reports


def _scope_rows_to_active_episode(
    appointments: List[Any],
    investigations: List[Any],
    referrals: List[Any],
    followups: List[Any],
    pharm_orders: List[Any],
    decision: Dict[str, Any],
) -> tuple[
    Optional[Dict[str, Any]],
    List[Dict[str, Any]],
    List[Dict[str, Any]],
    List[Dict[str, Any]],
    List[Dict[str, Any]],
    List[Dict[str, Any]],
    Dict[str, Any],
]:
    appointments_list = [dict(a) for a in (appointments or [])]
    active_appt = _pick_active_appointment(appointments_list)
    if not active_appt:
        return None, [], [], [], [], appointments_list, {}
    start, end = _episode_bounds_for_appt(appointments_list, active_appt)
    return (
        active_appt,
        _filter_episode_rows(investigations, start, end),
        _filter_episode_rows(referrals, start, end),
        _filter_episode_rows(followups, start, end),
        _filter_episode_rows(pharm_orders, start, end),
        appointments_list,
        _care_decision_for_episode(decision or {}, start),
    )


def _consultation_label(appt: Optional[Dict[str, Any]]) -> str:
    if not appt:
        return "NONE"
    if appt.get("cancelled"):
        return "CANCELLED"
    if appt.get("is_completed") or str(appt.get("status") or "").lower() == "completed":
        return "COMPLETED"
    life = str(appt.get("lifecycle_status") or "").upper()
    if life in {"MISSED", "NO_SHOW"}:
        return "MISSED"
    if life in {"IN_PROGRESS", "CHECKED_IN"}:
        return "IN_CONSULTATION"
    if life in {"COMPLETED", "FOLLOWUP_AVAILABLE", "CLOSED"}:
        return "COMPLETED"
    if life in {"BOOKED", "CONFIRMED", "ACCEPTED"}:
        return "SCHEDULED"
    status = str(appt.get("status") or "").lower()
    if status in {"pending", "confirmed"}:
        return "SCHEDULED"
    if status in {"missed", "no-show", "no_show"}:
        return "MISSED"
    return life or str(appt.get("status") or "UNKNOWN").upper()


def _investigation_labels(inv: Optional[Dict[str, Any]]) -> tuple[str, str]:
    if not inv:
        return "NONE", "NONE"
    status = str(inv.get("status") or "ORDERED").upper()
    if status == "REVIEWED":
        return "COMPLETED", "REVIEWED"
    if status == "REPORT_AVAILABLE":
        rrs = str(inv.get("report_review_status") or "PENDING").upper()
        if rrs == "REVIEWED":
            return "COMPLETED", "REVIEWED"
        return "COMPLETED", "PENDING_REVIEW"
    if status == "ORDERED":
        return "ORDERED", "PENDING"
    if status in {"ACCEPTED", "SAMPLE_COLLECTED", "TEST_PERFORMED"}:
        return "IN_PROGRESS", "PENDING"
    return status, "PENDING"


def _referral_labels(
    ref: Optional[Dict[str, Any]],
    spec_appt: Optional[Dict[str, Any]] = None,
) -> tuple[str, str]:
    if not ref:
        return "NONE", "NONE"
    status = str(ref.get("status") or "PENDING").upper()
    if status == "COMPLETED":
        return "COMPLETED", "COMPLETED"
    if status == "REJECTED":
        return "REJECTED", "NOT_SCHEDULED"

    if spec_appt:
        life = str(spec_appt.get("lifecycle_status") or spec_appt.get("status") or "").upper()
        ref_step = "REFERRED" if status == "PENDING" else status
        if spec_appt.get("is_completed") or life in {"COMPLETED", "CLOSED", "FOLLOWUP_AVAILABLE"}:
            return ref_step, "COMPLETED"
        if life in {"MISSED", "NO_SHOW"}:
            return ref_step, "MISSED"
        if life in {"BOOKED", "PENDING", ""}:
            return ref_step, "AWAITING_CONFIRMATION"
        if life in {"CONFIRMED", "CHECKED_IN", "IN_QUEUE", "IN_PROGRESS"}:
            return ref_step, "CONFIRMED"
        return ref_step, "CONFIRMED"

    booked = bool(ref.get("appointment_date")) or bool(ref.get("specialist_appointment_id")) or status in {
        "APPOINTMENT_BOOKED",
        "SPECIALIST_CONSULTATION",
        "COMPLETED",
    }
    if booked:
        return "REFERRED" if status == "PENDING" else status, "SCHEDULED"
    if status in {"PENDING"}:
        return "CREATED", "NOT_SCHEDULED"
    if status in {"ACCEPTED"}:
        return "ACCEPTED", "APPOINTMENT_PENDING"
    return status, "APPOINTMENT_PENDING"


async def _load_specialist_appointments(referrals: List[Any]) -> Dict[int, Dict[str, Any]]:
    """Map specialist_appointment_id -> appointment row for referral-linked visits."""
    out: Dict[int, Dict[str, Any]] = {}
    ids = {
        int(r.get("specialist_appointment_id"))
        for r in (referrals or [])
        if r.get("specialist_appointment_id") is not None
    }
    for aid in ids:
        try:
            row = await appointment_model.get_appointment_by_id(aid)
            if row:
                out[aid] = dict(row)
        except Exception as e:
            log.warning("specialist appointment load skipped id=%s: %s", aid, e)
    return out


def _referral_payload_row(
    r: Dict[str, Any],
    spec_appt: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    st = str(r.get("status") or "").upper()
    life = ""
    can_accept = False
    if spec_appt:
        life = str(spec_appt.get("lifecycle_status") or spec_appt.get("status") or "").upper()
        can_accept = (
            life in {"BOOKED", "PENDING", ""}
            and not spec_appt.get("is_completed")
            and not spec_appt.get("cancelled")
        )
    return {
        "id": r.get("id"),
        "to_dept": r.get("to_dept"),
        "reason": r.get("reason"),
        "status": st,
        "specialist_id": r.get("assigned_to"),
        "assigned_to": r.get("assigned_to"),
        "specialist_name": r.get("specialist_name"),
        "referring_doctor_name": r.get("referring_doctor_name"),
        "appointment_date": r.get("appointment_date"),
        "specialist_appointment_id": r.get("specialist_appointment_id"),
        "specialist_appointment_lifecycle": life or None,
        "can_accept_appointment": can_accept,
        "bookable": st == "ACCEPTED" and not r.get("specialist_appointment_id"),
    }


def _format_display_date(val: Any) -> Optional[str]:
    d = _as_date(val)
    if not d:
        return None
    return d.strftime("%d %b %Y")


def _followup_label(fol: Optional[Dict[str, Any]], today: Optional[date] = None) -> str:
    if not fol:
        return "NONE"
    status = str(fol.get("status") or "SCHEDULED").upper()
    if status == "COMPLETED":
        return "COMPLETED"
    due = _as_date(fol.get("due_date"))
    day = today or _today()
    if due and due < day:
        return "OVERDUE" if status != "OVERDUE" else "MISSED"
    if due and 0 <= (due - day).days <= 2:
        return "UPCOMING"
    if status == "SCHEDULED" and due:
        return "SCHEDULED"
    return status


def _pharmacy_label(order: Optional[Dict[str, Any]]) -> str:
    if not order:
        return "NONE"
    st = str(order.get("status") or "").lower()
    if st == "delivered":
        return "DELIVERED"
    if st == "cancelled":
        return "CANCELLED"
    if st in {"ready", "out_for_delivery"}:
        return "READY"
    if st == "paid":
        return "IN_PROGRESS"
    if st == "billed":
        return "PAYMENT_PENDING"
    if st == "placed":
        return "ORDERED"
    return (st or "IN_PROGRESS").upper()


def _patient_care_display(
    journey: Dict[str, str],
    inv: Optional[Dict[str, Any]],
    ref: Optional[Dict[str, Any]],
    fol: Optional[Dict[str, Any]],
    appt: Optional[Dict[str, Any]],
    user: Optional[Dict[str, Any]],
    pharm: Optional[Dict[str, Any]] = None,
) -> Dict[str, str]:
    """Human-readable pipeline labels for the patient My Care Journey view."""
    care: Dict[str, str] = {}

    care["registration"] = "Completed" if user else "Not yet created"

    if appt:
        care["problem"] = "Completed"
    else:
        care["problem"] = "Not yet created"

    life = str((appt or {}).get("lifecycle_status") or "").upper()
    if appt and (
        life in {"CONFIRMED", "CHECKED_IN", "IN_QUEUE", "IN_PROGRESS", "COMPLETED", "FOLLOWUP_AVAILABLE", "CLOSED"}
        or appt.get("is_completed")
    ):
        care["doctor_accepted"] = "Completed"
    elif appt:
        care["doctor_accepted"] = "Pending"
    else:
        care["doctor_accepted"] = "Not yet created"

    cons = journey.get("consultation", "NONE")
    cons_labels = {
        "COMPLETED": "Completed",
        "SCHEDULED": "Scheduled",
        "IN_CONSULTATION": "In progress",
        "MISSED": "Missed",
        "CANCELLED": "Cancelled",
        "NONE": "Not yet created",
    }
    care["consultation"] = cons_labels.get(cons, cons.replace("_", " ").title())

    inv_step = journey.get("investigation", "NONE")
    if inv:
        test = (inv.get("test_name") or "Investigation").strip()
        if inv_step == "COMPLETED":
            care["investigation"] = f"{test} Completed"
        elif inv_step == "IN_PROGRESS":
            care["investigation"] = f"{test} In progress"
        elif inv_step == "ORDERED":
            care["investigation"] = f"{test} Ordered"
        elif inv_step == "NOT_REQUIRED":
            care["investigation"] = "Not required"
        else:
            care["investigation"] = test
    elif inv_step == "NOT_REQUIRED":
        care["investigation"] = "Not required"
    else:
        care["investigation"] = "Not yet ordered"

    rep = journey.get("report", "NONE")
    if rep == "REVIEWED":
        care["report"] = "Available"
    elif rep in {"PENDING_REVIEW", "AVAILABLE"}:
        care["report"] = "Available"
    elif rep == "PENDING":
        care["report"] = "Pending"
    elif rep == "NOT_REQUIRED":
        care["report"] = "Not required"
    else:
        care["report"] = "Not yet available"

    dr = journey.get("doctor_review", "NONE")
    if dr == "COMPLETED":
        care["doctor_review"] = "Completed"
    elif dr == "PENDING":
        care["doctor_review"] = "Pending review"
    elif dr == "NOT_REQUIRED":
        care["doctor_review"] = "Not required"
    else:
        care["doctor_review"] = "Not yet applicable"

    ref_step = journey.get("referral", "NONE")
    spec_name = (ref or {}).get("specialist_name")
    if ref_step == "NOT_REQUIRED":
        care["referral"] = "Not required"
    elif ref_step == "NONE":
        care["referral"] = "Not yet created"
    elif ref_step == "REJECTED":
        dept = (ref or {}).get("to_dept")
        care["referral"] = f"Declined ({dept})" if dept else "Declined"
    elif ref_step in {"CREATED", "REFERRED", "ACCEPTED", "COMPLETED"}:
        dept = (ref or {}).get("to_dept")
        base = "Completed" if ref_step == "COMPLETED" else ("Accepted" if ref_step == "ACCEPTED" else "Created")
        if spec_name:
            base = f"{base} — {spec_name}"
        care["referral"] = f"{base} ({dept})" if dept else base
    else:
        care["referral"] = ref_step.replace("_", " ").title()

    spec = journey.get("specialist_appointment", "NONE")
    if spec == "NOT_REQUIRED":
        care["specialist_appointment"] = "Not required"
    elif spec == "NONE":
        care["specialist_appointment"] = "Not yet scheduled"
    elif spec == "APPOINTMENT_PENDING":
        care["specialist_appointment"] = (
            f"Awaiting booking with {spec_name}" if spec_name else "Awaiting booking"
        )
    elif spec == "AWAITING_CONFIRMATION":
        care["specialist_appointment"] = (
            f"Awaiting confirmation — {spec_name}" if spec_name else "Awaiting confirmation"
        )
    elif spec in {"SCHEDULED", "CONFIRMED"}:
        appt_dt = _format_display_date((ref or {}).get("appointment_date"))
        prefix = f"{spec_name} — " if spec_name else ""
        care["specialist_appointment"] = f"{prefix}{appt_dt}" if appt_dt else "Confirmed"
    elif spec == "COMPLETED":
        care["specialist_appointment"] = "Completed"
    elif spec == "MISSED":
        care["specialist_appointment"] = (
            f"Missed — reschedule with {spec_name}" if spec_name else "Missed — reschedule"
        )
    else:
        care["specialist_appointment"] = spec.replace("_", " ").title()

    fol_step = journey.get("followup", "NONE")
    due_label = _format_display_date((fol or {}).get("due_date"))
    if fol_step == "NONE":
        care["followup"] = "Not yet scheduled"
    elif fol_step == "NOT_REQUIRED":
        care["followup"] = "Not required"
    elif fol_step == "COMPLETED":
        care["followup"] = f"Completed ({due_label})" if due_label else "Completed"
    elif fol_step in {"SCHEDULED", "UPCOMING", "REMINDED"}:
        care["followup"] = due_label or "Scheduled"
    elif fol_step in {"OVERDUE", "MISSED"}:
        care["followup"] = f"Overdue ({due_label})" if due_label else "Overdue"
    else:
        care["followup"] = due_label or fol_step.replace("_", " ").title()

    pharm_step = journey.get("pharmacy", "NONE")
    if pharm_step == "NOT_REQUIRED":
        care["pharmacy"] = "Not required"
    elif pharm_step == "NONE":
        care["pharmacy"] = "Not yet ordered"
    elif pharm_step == "DELIVERED":
        care["pharmacy"] = "Delivered"
    elif pharm_step == "READY":
        care["pharmacy"] = "Ready for pickup"
    elif pharm_step == "PAYMENT_PENDING":
        care["pharmacy"] = "Payment pending"
    elif pharm_step == "ORDERED":
        care["pharmacy"] = "Order placed"
    elif pharm_step == "IN_PROGRESS":
        care["pharmacy"] = "In progress"
    else:
        care["pharmacy"] = pharm_step.replace("_", " ").title()

    return care


def _care_tones(care: Dict[str, str], journey: Dict[str, str]) -> Dict[str, str]:
    """UI tone per journey step: ok | warn | danger | muted."""
    import re

    referral_active = journey.get("referral") not in {"NONE", "NOT_REQUIRED", None, ""}
    tones: Dict[str, str] = {}
    for key, label in care.items():
        lv = str(label or "").lower().strip()
        jv = str(journey.get(key, "") or "").upper()

        if not lv or "not required" in lv or "not applicable" in lv:
            tones[key] = "muted"
            continue

        if key == "followup":
            if "completed" in lv:
                tones[key] = "ok"
            elif "overdue" in lv or jv in {"OVERDUE", "MISSED"}:
                tones[key] = "danger"
            elif jv in {"SCHEDULED", "UPCOMING", "REMINDED"} or re.search(r"\d", label or ""):
                tones[key] = "warn"
            else:
                tones[key] = "danger" if "not yet" in lv else "muted"
            continue

        if key == "referral":
            if "not yet" in lv:
                tones[key] = "danger"
            elif "completed" in lv or jv == "COMPLETED":
                tones[key] = "ok"
            elif "accepted" in lv or jv == "ACCEPTED":
                tones[key] = "ok"
            elif "created" in lv or jv in {"CREATED", "REFERRED", "PENDING"}:
                tones[key] = "warn"
            elif "declined" in lv or jv == "REJECTED":
                tones[key] = "danger"
            else:
                tones[key] = "danger"
            continue

        if key == "specialist_appointment":
            if "completed" in lv or jv == "COMPLETED":
                tones[key] = "ok"
            elif jv == "MISSED" or "missed" in lv:
                tones[key] = "danger"
            elif jv in {"APPOINTMENT_PENDING", "AWAITING_CONFIRMATION", "CONFIRMED", "SCHEDULED"}:
                tones[key] = "warn"
            elif "awaiting" in lv:
                tones[key] = "warn"
            elif re.search(r"\d", label or "") and "not" not in lv:
                tones[key] = "warn"
            elif "not yet" in lv or "not scheduled" in lv:
                tones[key] = "warn" if referral_active else "danger"
            else:
                tones[key] = "muted"
            continue

        if key == "pharmacy":
            if "delivered" in lv or "completed" in lv or jv == "DELIVERED":
                tones[key] = "ok"
            elif "ready" in lv:
                tones[key] = "warn"
            elif jv == "NONE" or "not yet" in lv:
                tones[key] = "warn"
            elif "pending" in lv or "payment" in lv or "placed" in lv or jv in {"ORDERED", "PAYMENT_PENDING", "IN_PROGRESS"}:
                tones[key] = "warn"
            elif "overdue" in lv or "declined" in lv:
                tones[key] = "danger"
            else:
                tones[key] = "muted"
            continue

        if (
            "not yet" in lv
            or "not scheduled" in lv
            or "not booked" in lv
            or "overdue" in lv
            or "declined" in lv
            or "pending review" in lv
            or (key == "doctor_review" and "pending" in lv)
            or (key == "report" and lv == "pending")
        ):
            tones[key] = "danger"
            continue

        if key == "consultation":
            if jv == "COMPLETED" or "completed" in lv:
                tones[key] = "ok"
            elif jv in {"SCHEDULED", "IN_CONSULTATION"} or "scheduled" in lv or "in progress" in lv:
                tones[key] = "warn"
            else:
                tones[key] = "danger" if "not yet" in lv else "muted"
            continue

        if key == "report" and "available" in lv:
            tones[key] = "ok"
        elif key == "investigation" and ("completed" in lv or jv == "COMPLETED"):
            tones[key] = "ok"
        elif key == "investigation" and jv in {"IN_PROGRESS", "ORDERED"}:
            tones[key] = "warn"
        elif "completed" in lv or jv == "COMPLETED":
            tones[key] = "ok"
        elif "pending" in lv or "awaiting" in lv:
            tones[key] = "warn"
        else:
            tones[key] = "muted"
    return tones


def _build_agent_activity(
    journey: Dict[str, str],
    findings: List[Dict[str, Any]],
    inv: Optional[Dict[str, Any]],
    ref: Optional[Dict[str, Any]],
    fol: Optional[Dict[str, Any]],
    journey_status: str = "ON_TRACK",
) -> List[Dict[str, Any]]:
    """Orchestrator-facing agent status for staff dashboard."""
    inv_findings = [f for f in findings if f.get("entity_type") == "investigation"]
    ref_findings = [f for f in findings if f.get("entity_type") == "referral"]
    fol_findings = [f for f in findings if f.get("entity_type") == "followup"]

    activities: List[Dict[str, Any]] = []

    if inv_findings:
        activities.append({
            "agent": "investigation",
            "icon": "🧪",
            "status": "attention",
            "message": inv_findings[0].get("message") or "Investigation coordination required",
        })
    elif inv and str(inv.get("status") or "").upper() == "REVIEWED":
        activities.append({"agent": "investigation", "icon": "🧪", "status": "ok", "message": "Investigation reviewed"})
    elif inv:
        activities.append({"agent": "investigation", "icon": "🧪", "status": "ok", "message": "Checked investigation status"})

    if ref_findings:
        top = ref_findings[0]
        ftype = str(top.get("finding_type") or "").upper()
        ref_status = "warn" if ftype in {"REFERRAL_APPOINTMENT_PENDING", "REFERRAL_DELAYED"} else "attention"
        activities.append({
            "agent": "referral",
            "icon": "📋",
            "status": ref_status,
            "message": top.get("message") or "Referral coordination required",
        })
    elif ref and str(ref.get("status") or "").upper() == "ACCEPTED":
        spec = ref.get("specialist_name") or "Specialist"
        activities.append({
            "agent": "referral",
            "icon": "📋",
            "status": "warn",
            "message": f"Referral accepted by {spec} — patient can book specialist appointment",
        })
    elif ref and str(ref.get("status") or "").upper() == "PENDING":
        spec = ref.get("specialist_name") or ref.get("to_dept") or "Specialist"
        activities.append({"agent": "referral", "icon": "📋", "status": "attention", "message": f"Referral to {spec} — awaiting specialist response"})
    elif ref and str(ref.get("status") or "").upper() == "APPOINTMENT_BOOKED":
        spec = ref.get("specialist_name") or "Specialist"
        spec_life = journey.get("specialist_appointment", "")
        if spec_life == "AWAITING_CONFIRMATION":
            activities.append({
                "agent": "referral",
                "icon": "📋",
                "status": "warn",
                "message": f"Specialist appointment booked with {spec} — awaiting confirmation",
            })
        else:
            activities.append({"agent": "referral", "icon": "📋", "status": "ok", "message": f"Specialist appointment booked with {spec}"})
    elif ref and journey.get("specialist_appointment") in {"SCHEDULED", "CONFIRMED"}:
        activities.append({"agent": "referral", "icon": "📋", "status": "ok", "message": "Specialist appointment scheduled"})
    elif ref:
        activities.append({"agent": "referral", "icon": "📋", "status": "ok", "message": "Referral tracked"})
    elif journey.get("consultation") == "COMPLETED":
        activities.append({"agent": "referral", "icon": "📋", "status": "attention", "message": "No referral created"})

    if fol_findings:
        activities.append({
            "agent": "followup",
            "icon": "📅",
            "status": "attention",
            "message": fol_findings[0].get("message") or "Follow-up attention required",
        })
    elif fol and journey.get("followup") in {"SCHEDULED", "UPCOMING", "REMINDED"}:
        due = _format_display_date(fol.get("due_date"))
        activities.append({
            "agent": "followup",
            "icon": "📅",
            "status": "warn",
            "message": f"Follow-up scheduled{f' for {due}' if due else ''}",
        })
    elif fol and journey.get("followup") in {"OVERDUE", "MISSED"}:
        activities.append({"agent": "followup", "icon": "📅", "status": "danger", "message": "Follow-up appointment overdue"})
    elif fol and journey.get("followup") == "COMPLETED":
        activities.append({"agent": "followup", "icon": "📅", "status": "ok", "message": "Follow-up completed"})

    pharm_findings = [f for f in findings if f.get("entity_type") in {"pharmacy", "pharmacy_order"}]
    appt_findings = [f for f in findings if f.get("entity_type") == "appointment"]
    if pharm_findings:
        activities.append({
            "agent": "pharmacy",
            "icon": "💊",
            "status": "attention",
            "message": pharm_findings[0].get("message") or "Pharmacy coordination required",
        })
    elif journey.get("pharmacy") in {"DELIVERED", "COMPLETED"}:
        activities.append({"agent": "pharmacy", "icon": "💊", "status": "ok", "message": "Pharmacy order completed"})
    elif journey.get("pharmacy") not in {"NONE", "NOT_REQUIRED"}:
        activities.append({"agent": "pharmacy", "icon": "💊", "status": "ok", "message": "Pharmacy order tracked"})

    if appt_findings:
        top = appt_findings[0]
        ftype = str(top.get("finding_type") or "").upper()
        appt_status = "warn" if ftype == "APPOINTMENT_AWAITING_CONFIRMATION" else "attention"
        activities.append({
            "agent": "appointment",
            "icon": "🗓️",
            "status": appt_status,
            "message": top.get("message") or "Appointment coordination required",
        })
    elif journey.get("consultation") == "COMPLETED":
        activities.append({"agent": "appointment", "icon": "🗓️", "status": "ok", "message": "Consultation completed"})
    elif journey.get("doctor_accepted") == "COMPLETED":
        activities.append({"agent": "appointment", "icon": "🗓️", "status": "ok", "message": "Appointment confirmed"})
    elif journey.get("consultation") == "MISSED":
        activities.append({"agent": "appointment", "icon": "🗓️", "status": "danger", "message": "Consultation missed — reschedule required"})

    if findings or journey_status in {"ATTENTION_REQUIRED", "OVERDUE"}:
        activities.append({
            "agent": "orchestrator",
            "icon": "🧠",
            "status": "attention" if journey_status != "OVERDUE" else "danger",
            "message": "Overdue — urgent attention required" if journey_status == "OVERDUE" else "Coordination attention required",
        })
    elif journey_status == "UPCOMING":
        activities.append({
            "agent": "orchestrator",
            "icon": "🧠",
            "status": "warn",
            "message": "Upcoming actions scheduled — journey on track",
        })
    else:
        activities.append({
            "agent": "orchestrator",
            "icon": "🧠",
            "status": "ok",
            "message": "Journey on track",
        })
    return activities


def finding_still_valid(finding: Dict[str, Any], entity: Optional[Dict[str, Any]]) -> bool:
    """True only if the live database row still matches the finding condition."""
    ftype = (finding.get("finding_type") or "").upper()
    message = (finding.get("message") or "").lower()
    if entity is None:
        return False
    status = str(entity.get("status") or "").upper()

    if ftype == "REPORT_REVIEW_PENDING" or "requires doctor review" in message:
        rrs = str(entity.get("report_review_status") or "PENDING").upper()
        return status == "REPORT_AVAILABLE" and rrs == "PENDING"
    if ftype in {"INVESTIGATION_DELAYED", "INVESTIGATION_PENDING"} or "investigation pending" in message:
        return status in {"ORDERED", "ACCEPTED", "SAMPLE_COLLECTED", "TEST_PERFORMED"}
    if ftype == "REFERRAL_NO_SPECIALIST":
        return not entity.get("assigned_to")
    if ftype in {"REFERRAL_AWAITING_SPECIALIST", "REFERRAL_DELAYED"} and "awaiting specialist" in message:
        return str(entity.get("status") or "").upper() == "PENDING"
    if ftype in {"REFERRAL_APPOINTMENT_PENDING", "REFERRAL_DELAYED"} or "specialist appointment" in message:
        booked = bool(entity.get("appointment_date")) or status in {
            "APPOINTMENT_BOOKED",
            "SPECIALIST_CONSULTATION",
            "COMPLETED",
        }
        return not booked
    if ftype == "FOLLOWUP_UPCOMING" or "due soon" in message:
        due = _as_date(entity.get("due_date"))
        if not due or status == "COMPLETED":
            return False
        return 0 <= (due - _today()).days <= 2
    if ftype in {"FOLLOWUP_OVERDUE", "FOLLOWUP_MISSED"} or "overdue" in message:
        due = _as_date(entity.get("due_date"))
        return status != "COMPLETED" and bool(due and due < _today())
    if finding.get("entity_type") == "pharmacy":
        pstatus = str(entity.get("status") or "").lower()
        if ftype == "PHARMACY_ORDER_PENDING":
            return pstatus == "placed"
        if ftype == "PHARMACY_PAYMENT_PENDING":
            return pstatus == "billed"
        if ftype == "PHARMACY_READY_NOT_COLLECTED":
            return pstatus == "ready"
        return pstatus not in {"delivered", "cancelled"}
    if finding.get("entity_type") == "appointment":
        life = str(entity.get("lifecycle_status") or entity.get("status") or "").upper()
        if ftype == "APPOINTMENT_AWAITING_CONFIRMATION":
            return life in {"BOOKED", "PENDING", ""} and life not in {"CONFIRMED", "CHECKED_IN", "IN_PROGRESS", "COMPLETED"}
        if ftype in {"APPOINTMENT_MISSED", "APPOINTMENT_NOT_COMPLETED"}:
            return not entity.get("is_completed") and life not in {"COMPLETED", "CANCELLED", "CLOSED"}
        return life not in {"COMPLETED", "CANCELLED", "CLOSED"}
    return status not in {"REVIEWED", "COMPLETED"}


async def load_entity(entity_type: str, entity_id: int) -> Optional[Dict[str, Any]]:
    if entity_type == "investigation":
        row = await investigation_model.get_investigation_by_id(entity_id)
    elif entity_type == "referral":
        row = await referral_model.get_referral_by_id(entity_id)
    elif entity_type == "followup":
        row = await followup_model.get_followup_by_id(entity_id)
    elif entity_type == "pharmacy":
        row = await pharmacy_order_model.get_by_id(entity_id)
    elif entity_type == "appointment":
        row = await appointment_model.get_appointment_by_id(entity_id)
    else:
        return None
    return dict(row) if row else None


async def verify_and_close_stale_findings(patient_id: Optional[int] = None) -> int:
    if patient_id is not None:
        findings = await order_finding_model.get_open_findings_by_patient(patient_id)
    else:
        findings = await order_finding_model.get_all_open_findings(limit=150)

    closed = 0
    for finding in findings:
        entity = await load_entity(finding["entity_type"], finding["entity_id"])
        if finding_still_valid(finding, entity):
            continue
        await order_finding_model.update_finding_status(finding["id"], "RESOLVED")
        await order_event_model.create_order_event(
            entity_type=finding["entity_type"],
            entity_id=finding["entity_id"],
            event_type="FINDING_RESOLVED",
            payload={"finding_id": finding["id"], "reason": "database_state_verified"},
        )
        closed += 1
    return closed


def _priority_from_findings(findings: List[Dict[str, Any]]) -> str:
    rank = 0
    for f in findings:
        rank = max(rank, PRIORITY_RANK.get(str(f.get("priority") or "LOW").upper(), 0))
    if rank >= 3:
        return "HIGH"
    if rank == 2:
        return "MEDIUM"
    if rank == 1:
        return "LOW"
    return "NONE"


def _pending_severity(journey: Dict[str, str], findings: List[Dict[str, Any]]) -> str:
    """Classify remaining journey work as critical, soft, or none."""
    if journey.get("doctor_review") == "PENDING" and journey.get("report") in {"AVAILABLE", "PENDING_REVIEW"}:
        return "critical"
    if journey.get("consultation") == "MISSED":
        return "critical"
    if journey.get("followup") in {"OVERDUE", "MISSED"}:
        return "critical"
    if journey.get("specialist_appointment") == "MISSED":
        return "critical"
    if journey.get("referral") in {"CREATED", "REFERRED"}:
        return "critical"
    if journey.get("consultation") == "COMPLETED" and journey.get("referral") == "NONE":
        return "critical"
    if any(str(f.get("priority")) == "HIGH" for f in findings):
        return "critical"

    soft = False
    journey_winding_down = journey.get("followup") == "COMPLETED" and journey.get("specialist_appointment") in {
        "CONFIRMED",
        "COMPLETED",
        "NOT_REQUIRED",
    }
    if journey.get("specialist_appointment") in {
        "APPOINTMENT_PENDING",
        "AWAITING_CONFIRMATION",
        "NOT_SCHEDULED",
        "SCHEDULED",
    } and journey.get("referral") in {"ACCEPTED", "APPOINTMENT_BOOKED", "REFERRED"}:
        soft = True
    if journey.get("specialist_appointment") == "CONFIRMED" and journey.get("followup") not in {
        "COMPLETED",
        "NOT_REQUIRED",
        "NONE",
    }:
        soft = True
    if journey.get("followup") in {"UPCOMING", "SCHEDULED", "REMINDED"}:
        soft = True
    if (
        journey.get("pharmacy") == "NONE"
        and journey.get("referral") not in {"NONE", "NOT_REQUIRED"}
        and not journey_winding_down
    ):
        soft = True
    if journey.get("doctor_accepted") == "PENDING":
        soft = True
    if any(str(f.get("priority")) in {"MEDIUM", "LOW"} for f in findings):
        soft = True
    if soft:
        return "soft"
    return "none"


def _journey_status(journey: Dict[str, str], findings: List[Dict[str, Any]]) -> str:
    if journey.get("followup") in {"OVERDUE", "MISSED"}:
        return "OVERDUE"
    severity = _pending_severity(journey, findings)
    if severity == "critical":
        return "OVERDUE" if journey.get("followup") in {"OVERDUE", "MISSED"} else "ATTENTION_REQUIRED"
    if severity == "soft":
        return "UPCOMING"
    if findings:
        if all(str(f.get("priority")) in {"LOW", "MEDIUM"} for f in findings):
            return "UPCOMING"
        return "ATTENTION_REQUIRED"
    if journey.get("followup") in {"UPCOMING", "SCHEDULED", "REMINDED"}:
        return "UPCOMING"
    return "ON_TRACK"


def _dedupe_findings(findings: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    seen = set()
    out = []
    for f in findings:
        key = (f.get("finding_type") or f.get("message"), f.get("entity_type"), f.get("entity_id"))
        if key in seen:
            continue
        seen.add(key)
        out.append(f)
    return out


def _template_summary(journey: Dict[str, str], findings: List[Dict[str, Any]]) -> str:
    if not findings:
        return "The patient journey is on track. No coordination steps are missing."
    parts = [str(f.get("message") or "").rstrip(".") for f in findings if f.get("message")]
    unique = []
    for p in parts:
        if p and p not in unique:
            unique.append(p)
    if len(unique) == 1:
        return unique[0] + "."
    return "; ".join(unique[:-1]) + ", and " + unique[-1] + "."


def _recommendations(findings: List[Dict[str, Any]]) -> List[str]:
    recs = []
    for f in findings:
        action = (f.get("recommended_action") or "").strip()
        if action and action not in recs:
            recs.append(action)
    return recs


async def _llm_summary(journey: Dict[str, str], findings: List[Dict[str, Any]], patient_name: str) -> Optional[str]:
    try:
        from app.services.ai import provider
    except Exception:
        return None
    if not getattr(provider, "is_configured", lambda: False)():
        return None
    facts = {
        "patient_name": patient_name,
        "journey": journey,
        "findings": [
            {
                "type": f.get("finding_type"),
                "priority": f.get("priority"),
                "message": f.get("message"),
            }
            for f in findings
        ],
    }
    result = await provider.complete_text(
        system_prompt=(
            "You are a MEDCLUES care-coordination assistant. "
            "Write one or two sentences summarizing coordination issues only. "
            "Use only the supplied facts. Do not diagnose, prescribe, or invent data."
        ),
        user_message="Summarize the coordination status for staff.",
        grounding=str(facts),
    )
    if result.success and (result.content or "").strip():
        return result.content.strip()[:600]
    return None


async def _specialist_name(ref: Optional[Dict[str, Any]]) -> Optional[str]:
    if not ref:
        return None
    if ref.get("specialist_name"):
        return str(ref["specialist_name"])
    if not ref.get("assigned_to"):
        return None
    doc = await doctor_model.get_doctor_by_id(int(ref["assigned_to"]))
    if doc:
        return doc.get("name")
    return None


async def _build_episode_payload(
    *,
    patient_id: int,
    user: Dict[str, Any],
    appt: Optional[Dict[str, Any]],
    investigations: List[Dict[str, Any]],
    referrals: List[Dict[str, Any]],
    followups: List[Dict[str, Any]],
    pharm_orders: List[Dict[str, Any]],
    decision: Dict[str, Any],
    lookup_doctor: bool = True,
) -> Dict[str, Any]:
    """Build one appointment-scoped journey episode for the patient view."""
    inv = dict(_latest([dict(x) for x in investigations]) or {}) or None
    if inv == {}:
        inv = None
    ref = dict(_latest([dict(x) for x in referrals]) or {}) or None
    if ref == {}:
        ref = None
    fol = dict(_latest([dict(x) for x in followups]) or {}) or None
    if fol == {}:
        fol = None
    pharm = dict(pharm_orders[0]) if pharm_orders else None

    inv_status, report_status = _investigation_labels(inv)
    if not inv and decision.get("investigation_required") is False:
        inv_status, report_status = "NOT_REQUIRED", "NOT_REQUIRED"
    spec_appt_map = await _load_specialist_appointments(referrals)
    ref_spec_appt = None
    if ref and ref.get("specialist_appointment_id"):
        ref_spec_appt = spec_appt_map.get(int(ref["specialist_appointment_id"]))
    ref_status, spec_status = _referral_labels(ref, ref_spec_appt)
    if not ref and decision.get("referral_required") is False:
        ref_status = "NOT_REQUIRED"
        if decision.get("specialist_required") is False:
            spec_status = "NOT_REQUIRED"
    elif not ref:
        spec_status = spec_status if spec_status != "NONE" else "NONE"
    if not ref and decision.get("specialist_required") is False:
        spec_status = "NOT_REQUIRED"

    life = str((appt or {}).get("lifecycle_status") or "").upper()
    problem = "REPORTED" if appt else "NONE"
    doctor_accepted = (
        "COMPLETED"
        if life in {"CONFIRMED", "CHECKED_IN", "IN_QUEUE", "IN_PROGRESS", "COMPLETED", "FOLLOWUP_AVAILABLE", "CLOSED"}
        or (appt and appt.get("is_completed"))
        else ("PENDING" if appt else "NONE")
    )
    doctor_review = (
        "COMPLETED"
        if report_status == "REVIEWED"
        else ("PENDING" if report_status == "PENDING_REVIEW" else ("NOT_REQUIRED" if report_status == "NOT_REQUIRED" else "NONE"))
    )
    pharm_status = _pharmacy_label(pharm)

    journey = {
        "registration": "COMPLETED" if user else "NONE",
        "problem": problem,
        "doctor_accepted": doctor_accepted,
        "consultation": _consultation_label(appt),
        "investigation": inv_status,
        "report": report_status,
        "doctor_review": doctor_review,
        "pharmacy": pharm_status,
        "referral": ref_status,
        "specialist_appointment": spec_status,
        "followup": _followup_label(fol),
    }

    journey_status = _journey_status(journey, [])
    care_display = _patient_care_display(journey, inv, ref, fol, appt, user, pharm)
    care_tones = _care_tones(care_display, journey)

    reports = _episode_report_rows(investigations)

    active_referrals: List[Dict[str, Any]] = []
    for row in referrals or []:
        r = dict(row)
        st = str(r.get("status") or "").upper()
        if st == "COMPLETED":
            continue
        for field in ("created_at", "updated_at", "appointment_date"):
            val = r.get(field)
            if val and hasattr(val, "isoformat"):
                r[field] = val.isoformat()
        sid = r.get("specialist_appointment_id")
        spec_appt = spec_appt_map.get(int(sid)) if sid else None
        active_referrals.append(_referral_payload_row(r, spec_appt))

    if reports and str(reports[0].get("status") or "").upper() == "REPORT_AVAILABLE":
        care_display = dict(care_display)
        care_display["report"] = "Available"
    if inv:
        inv_st = str(inv.get("status") or "").upper()
        rrs = str(inv.get("report_review_status") or "").upper()
        care_display = dict(care_display)
        if rrs == "REVIEWED":
            care_display["doctor_review"] = "Completed"
        elif inv_st in {"REPORT_AVAILABLE", "REVIEWED"}:
            care_display["doctor_review"] = "In progress"
        care_tones = _care_tones(care_display, journey)

    doctor_display = _format_doctor_display(_appt_doctor_name(appt))
    if lookup_doctor and appt and not doctor_display:
        doc_id = appt.get("doctor_id") or appt.get("docId")
        if doc_id:
            try:
                doc = await doctor_model.get_doctor_by_id(int(doc_id))
                if doc:
                    doctor_display = _format_doctor_display(doc.get("name"))
            except Exception:
                pass

    return {
        "appointment_id": appt.get("id") if appt else None,
        "doctor_name": doctor_display,
        "slot_date": _appt_slot_date(appt),
        "slot_time": (appt or {}).get("slotTime") or (appt or {}).get("slot_time"),
        "label": _episode_label(appt) if appt else None,
        "journey_status": _patient_journey_status_label(journey_status),
        "care": care_display,
        "care_tones": care_tones,
        "referrals": active_referrals,
        "reports": reports,
        "closed_at": _iso((appt or {}).get("updated_at") or (appt or {}).get("created_at")),
    }


async def _fresh_active_episode(user: Dict[str, Any]) -> Dict[str, Any]:
    journey = {
        "registration": "COMPLETED",
        "problem": "NONE",
        "doctor_accepted": "NONE",
        "consultation": "NONE",
        "investigation": "NONE",
        "report": "NONE",
        "doctor_review": "NONE",
        "pharmacy": "NONE",
        "referral": "NONE",
        "specialist_appointment": "NONE",
        "followup": "NONE",
    }
    care_display = _patient_care_display(journey, None, None, None, None, user, None)
    care_tones = _care_tones(care_display, journey)
    return {
        "appointment_id": None,
        "doctor_name": None,
        "slot_date": None,
        "slot_time": None,
        "label": None,
        "journey_status": "UPCOMING",
        "care": care_display,
        "care_tones": care_tones,
        "referrals": [],
        "reports": [],
        "closed_at": None,
    }


async def archive_episode_snapshot(patient_id: int, appointment_id: int) -> None:
    """Save a closed visit journey snapshot for Past My Journey history."""
    from app.models import patient_journey_episode_model

    try:
        user = await user_model.get_user_by_id(int(patient_id))
        if not user:
            return
        appointments_list = [
            dict(a)
            for a in await appointment_model.get_appointments_by_user_id(
                int(patient_id), limit=PATIENT_APPOINTMENT_LIMIT
            )
        ]
        idx = next(
            (i for i, a in enumerate(appointments_list) if int(a.get("id") or 0) == int(appointment_id)),
            None,
        )
        if idx is None:
            return
        appt_row = appointments_list[idx]
        start = appointments_list[idx].get("created_at")
        end = appointments_list[idx - 1].get("created_at") if idx > 0 else None

        investigations, referrals, followups, pharm_orders, decision = await asyncio.gather(
            investigation_model.get_investigations_by_patient(int(patient_id)),
            referral_model.get_referrals_by_patient(int(patient_id)),
            followup_model.get_followups_by_patient(int(patient_id)),
            pharmacy_order_model.list_for_patient(int(patient_id), limit=15),
            _safe_care_decision(int(patient_id)),
        )
        ep_decision = _care_decision_for_episode(decision or {}, start)
        payload = await _build_episode_payload(
            patient_id=int(patient_id),
            user=user,
            appt=appt_row,
            investigations=_filter_episode_rows(investigations, start, end),
            referrals=_filter_episode_rows(referrals, start, end),
            followups=_filter_episode_rows(followups, start, end),
            pharm_orders=_filter_episode_rows(pharm_orders, start, end),
            decision=ep_decision,
            lookup_doctor=False,
        )
        payload["label"] = payload.get("label") or _episode_label(appt_row)
        await patient_journey_episode_model.upsert_episode(
            patient_id=int(patient_id),
            appointment_id=int(appointment_id),
            episode_label=payload.get("label"),
            journey_status=payload.get("journey_status"),
            payload=payload,
        )
        invalidate_patient_journey_cache(int(patient_id))
    except Exception as e:
        log.warning(
            "archive episode snapshot failed patient=%s appt=%s: %s",
            patient_id,
            appointment_id,
            e,
        )


async def _merge_saved_past_episodes(
    patient_id: int,
    past_episodes: List[Dict[str, Any]],
    *,
    active_appointment_id: Optional[int] = None,
) -> List[Dict[str, Any]]:
    """Merge DB-persisted snapshots so history survives appointment list limits."""
    from app.models import patient_journey_episode_model

    try:
        saved_rows = await patient_journey_episode_model.list_for_patient(
            int(patient_id), limit=PAST_EPISODES_MAX
        )
    except Exception as e:
        log.warning("saved journey episodes skipped patient=%s: %s", patient_id, e)
        return past_episodes

    by_appt: Dict[int, Dict[str, Any]] = {
        int(ep["appointment_id"]): ep
        for ep in past_episodes
        if ep.get("appointment_id") is not None
    }
    active_id = int(active_appointment_id) if active_appointment_id is not None else None

    for row in saved_rows:
        aid = int(row.get("appointment_id") or 0)
        if not aid or aid == active_id:
            continue
        payload = dict(row.get("payload") or {})
        if not payload.get("appointment_id"):
            payload["appointment_id"] = aid
        if row.get("episode_label"):
            payload["label"] = row["episode_label"]
        if row.get("journey_status"):
            payload["journey_status"] = row["journey_status"]
        if row.get("closed_at"):
            payload["closed_at"] = row["closed_at"]
        existing = by_appt.get(aid)
        if existing:
            if row.get("closed_at") and (
                not existing.get("closed_at")
                or str(row["closed_at"]) > str(existing.get("closed_at"))
            ):
                by_appt[aid] = payload
        else:
            by_appt[aid] = payload

    merged = list(by_appt.values())
    merged.sort(key=lambda ep: str(ep.get("closed_at") or ""), reverse=True)
    return merged[:PAST_EPISODES_MAX]


async def _build_patient_episodes_view(
    *,
    patient_id: int,
    user: Dict[str, Any],
    appointments: List[Any],
    investigations: List[Any],
    referrals: List[Any],
    followups: List[Any],
    pharm_orders: List[Any],
    decision: Dict[str, Any],
    patient_notes: List[Any],
) -> Dict[str, Any]:
    appointments_list = [dict(a) for a in (appointments or [])]
    active_appt = _pick_active_appointment(appointments_list)
    scoped_notes: List[Any] = []

    def _bounds(idx: int) -> tuple[Any, Any]:
        start = appointments_list[idx].get("created_at")
        end = appointments_list[idx - 1].get("created_at") if idx > 0 else None
        return start, end

    if active_appt:
        active_idx = next(
            i for i, row in enumerate(appointments_list) if row.get("id") == active_appt.get("id")
        )
        start, end = _bounds(active_idx)
        scoped_notes = _filter_episode_notifications(
            patient_notes,
            start,
            end,
            appointment_id=active_appt.get("id"),
        )
        ep_decision = _care_decision_for_episode(decision, start)
        active_episode = await _build_episode_payload(
            patient_id=patient_id,
            user=user,
            appt=active_appt,
            investigations=_filter_episode_rows(investigations, start, end),
            referrals=_filter_episode_rows(referrals, start, end),
            followups=_filter_episode_rows(followups, start, end),
            pharm_orders=_filter_episode_rows(pharm_orders, start, end),
            decision=ep_decision,
            lookup_doctor=True,
        )
    else:
        active_episode = await _fresh_active_episode(user)

    past_episodes: List[Dict[str, Any]] = []
    past_tasks: List[Any] = []
    past_meta: List[tuple[int, Dict[str, Any]]] = []
    for i, appt_row in enumerate(appointments_list):
        if active_appt and appt_row.get("id") == active_appt.get("id"):
            continue
        if len(past_meta) >= PAST_EPISODES_MAX:
            break
        start, end = _bounds(i)
        ep_decision = _care_decision_for_episode(decision, start)
        past_meta.append((i, appt_row))
        past_tasks.append(
            _build_episode_payload(
                patient_id=patient_id,
                user=user,
                appt=appt_row,
                investigations=_filter_episode_rows(investigations, start, end),
                referrals=_filter_episode_rows(referrals, start, end),
                followups=_filter_episode_rows(followups, start, end),
                pharm_orders=_filter_episode_rows(pharm_orders, start, end),
                decision=ep_decision,
                lookup_doctor=False,
            )
        )
    if past_tasks:
        built_past = await asyncio.gather(*past_tasks)
        for (i, appt_row), past_ep in zip(past_meta, built_past):
            past_ep["label"] = past_ep.get("label") or _episode_label(appt_row)
            past_episodes.append(past_ep)

    past_episodes = await _merge_saved_past_episodes(
        patient_id,
        past_episodes,
        active_appointment_id=active_appt.get("id") if active_appt else None,
    )

    for past_ep in past_episodes:
        aid = past_ep.get("appointment_id")
        if aid:
            asyncio.create_task(archive_episode_snapshot(patient_id, int(aid)))

    return {
        "success": True,
        "patient_id": patient_id,
        "patient_name": user.get("name"),
        "has_active_appointment": bool(active_appt),
        "active_episode": active_episode,
        "past_episodes": past_episodes,
        "notifications": [
            {
                "id": n.get("id"),
                "title": n.get("title"),
                "body": n.get("body"),
                "created_at": _iso(n.get("created_at")),
            }
            for n in scoped_notes
        ],
    }


async def build_patient_journey(patient_id: int, *, staff_view: bool = True) -> Dict[str, Any]:
    if not staff_view:
        cached = _PATIENT_JOURNEY_CACHE.get(patient_id)
        if cached and (time.monotonic() - cached[0]) < _PATIENT_JOURNEY_TTL_SEC:
            return cached[1]

    user = await user_model.get_user_by_id(patient_id)
    if not user:
        return {"success": False, "message": "Patient not found"}

    gather_tasks: List[Any]
    if staff_view:
        gather_tasks = [
            _limited_db(appointment_model.get_appointments_by_user_id(patient_id, limit=5)),
            _limited_db(investigation_model.get_investigations_by_patient(patient_id)),
            _limited_db(referral_model.get_referrals_by_patient(patient_id)),
            _limited_db(followup_model.get_followups_by_patient(patient_id)),
            _limited_db(pharmacy_order_model.list_for_patient(patient_id, limit=5)),
            _limited_db(_safe_care_decision(patient_id)),
            _limited_db(order_finding_model.get_open_findings_by_patient(patient_id)),
        ]
    else:
        gather_tasks = [
            appointment_model.get_appointments_by_user_id(patient_id, limit=PATIENT_APPOINTMENT_LIMIT),
            investigation_model.get_investigations_by_patient(patient_id),
            referral_model.get_referrals_by_patient(patient_id),
            followup_model.get_followups_by_patient(patient_id),
            pharmacy_order_model.list_for_patient(patient_id, limit=15),
            _safe_care_decision(patient_id),
            _safe_patient_notifications(patient_id),
        ]

    gathered = await asyncio.gather(*gather_tasks)
    if staff_view:
        (
            appointments,
            investigations,
            referrals,
            followups,
            pharm_orders,
            decision,
            open_findings_raw,
        ) = gathered
        patient_notes = []
    else:
        (
            appointments,
            investigations,
            referrals,
            followups,
            pharm_orders,
            decision,
            patient_notes,
        ) = gathered
        open_findings_raw = []
        investigations = list(investigations or [])[:40]
        referrals = list(referrals or [])[:25]
        followups = list(followups or [])[:25]
        result = await _build_patient_episodes_view(
            patient_id=patient_id,
            user=user,
            appointments=appointments or [],
            investigations=investigations or [],
            referrals=referrals or [],
            followups=followups or [],
            pharm_orders=pharm_orders or [],
            decision=decision or {},
            patient_notes=patient_notes or [],
        )
        _PATIENT_JOURNEY_CACHE[patient_id] = (time.monotonic(), result)
        return result

    (
        appt,
        investigations,
        referrals,
        followups,
        pharm_orders,
        _appointments_list,
        decision,
    ) = _scope_rows_to_active_episode(
        appointments or [],
        investigations or [],
        referrals or [],
        followups or [],
        pharm_orders or [],
        decision or {},
    )

    inv = dict(_latest([dict(x) for x in investigations]) or {}) or None
    if inv == {}:
        inv = None
    ref = dict(_latest([dict(x) for x in referrals]) or {}) or None
    if ref == {}:
        ref = None
    fol = dict(_latest([dict(x) for x in followups]) or {}) or None
    if fol == {}:
        fol = None
    pharm = dict(pharm_orders[0]) if pharm_orders else None

    inv_status, report_status = _investigation_labels(inv)
    if not inv and decision.get("investigation_required") is False:
        inv_status, report_status = "NOT_REQUIRED", "NOT_REQUIRED"
    spec_appt_map = await _load_specialist_appointments(referrals)
    ref_spec_appt = None
    if ref and ref.get("specialist_appointment_id"):
        ref_spec_appt = spec_appt_map.get(int(ref["specialist_appointment_id"]))
    ref_status, spec_status = _referral_labels(ref, ref_spec_appt)
    if not ref and decision.get("referral_required") is False:
        ref_status = "NOT_REQUIRED"
        if decision.get("specialist_required") is False:
            spec_status = "NOT_REQUIRED"
    elif not ref:
        spec_status = spec_status if spec_status != "NONE" else "NONE"
    if not ref and decision.get("specialist_required") is False:
        spec_status = "NOT_REQUIRED"

    life = str((appt or {}).get("lifecycle_status") or "").upper()
    registration = "COMPLETED" if user else "NONE"
    problem = "REPORTED" if appt else "NONE"
    doctor_accepted = "COMPLETED" if life in {"CONFIRMED", "CHECKED_IN", "IN_QUEUE", "IN_PROGRESS", "COMPLETED", "FOLLOWUP_AVAILABLE", "CLOSED"} or (appt and appt.get("is_completed")) else ("PENDING" if appt else "NONE")
    doctor_review = "COMPLETED" if report_status == "REVIEWED" else ("PENDING" if report_status == "PENDING_REVIEW" else ("NOT_REQUIRED" if report_status == "NOT_REQUIRED" else "NONE"))
    pharm_status = _pharmacy_label(pharm)

    journey = {
        "registration": registration,
        "problem": problem,
        "doctor_accepted": doctor_accepted,
        "consultation": _consultation_label(appt),
        "investigation": inv_status,
        "report": report_status,
        "doctor_review": doctor_review,
        "pharmacy": pharm_status,
        "referral": ref_status,
        "specialist_appointment": spec_status,
        "followup": _followup_label(fol),
    }

    open_findings = [
        order_finding_model.normalize_finding(f)
        for f in open_findings_raw
    ]
    open_findings = _dedupe_findings(open_findings)
    open_findings = _filter_findings_to_episode(
        open_findings,
        investigations=[dict(x) for x in investigations],
        referrals=[dict(x) for x in referrals],
        followups=[dict(x) for x in followups],
        pharm_orders=[dict(x) for x in pharm_orders],
        appt=appt,
    )
    priority = _priority_from_findings(open_findings)
    journey_status = _journey_status(journey, open_findings)

    specialist = ref.get("specialist_name") if ref else None
    if ref and not specialist:
        specialist = await _limited_db(_specialist_name(ref))
    evidence: List[Dict[str, Any]] = []
    if inv:
        evidence.append({
            "type": "investigation",
            "id": inv.get("id"),
            "test_name": inv.get("test_name"),
            "ordered": _iso(inv.get("created_at")),
            "completed": _iso(inv.get("updated_at")) if inv_status in {"COMPLETED", "REPORT_AVAILABLE", "REVIEWED"} else None,
            "report": "Available" if report_status in {"PENDING_REVIEW", "REVIEWED"} or bool(inv.get("report_url")) else "Not available",
            "reviewed": "Reviewed" if str(inv.get("report_review_status") or "").upper() == "REVIEWED" or inv.get("reviewed_at") else "Pending",
            "report_review_status": inv.get("report_review_status"),
            "status": inv.get("status"),
        })
    if ref:
        evidence.append({
            "type": "referral",
            "id": ref.get("id"),
            "created": _iso(ref.get("created_at")),
            "accepted": _iso(ref.get("updated_at")) if str(ref.get("status")) in {"ACCEPTED", "APPOINTMENT_BOOKED", "SPECIALIST_CONSULTATION", "COMPLETED"} else None,
            "specialist": specialist or "Not assigned",
            "to_dept": ref.get("to_dept"),
            "appointment": _iso(ref.get("appointment_date")) or "Not booked",
            "status": ref.get("status"),
        })
    if fol:
        evidence.append({
            "type": "followup",
            "id": fol.get("id"),
            "followup": _iso(fol.get("due_date")),
            "status": journey["followup"],
            "reason": fol.get("reason") or fol.get("instructions"),
        })
    if pharm:
        evidence.append({
            "type": "pharmacy",
            "id": pharm.get("id"),
            "public_id": pharm.get("public_id"),
            "status": pharm.get("status"),
            "pharmacy": pharm.get("pharmacy_name"),
            "created": _iso(pharm.get("created_at")),
        })

    recommendations = _recommendations(open_findings)
    summary = _template_summary(journey, open_findings)
    agent_activity = _build_agent_activity(journey, open_findings, inv, ref, fol, journey_status)
    care_display = _patient_care_display(journey, inv, ref, fol, appt, user, pharm)
    care_tones = _care_tones(care_display, journey)
    if staff_view and open_findings:
        llm = await _llm_summary(journey, open_findings, user.get("name") or "Patient")
        if llm:
            summary = llm

    payload: Dict[str, Any] = {
        "success": True,
        "patient_id": patient_id,
        "patient_name": user.get("name"),
        "journey_status": journey_status,
        "priority": priority if open_findings else "NONE",
        "journey": journey,
        "care": care_display,
        "care_tones": care_tones,
        "agent_activity": agent_activity if staff_view else [],
        "findings": open_findings if staff_view else [],
        "evidence": evidence if staff_view else [],
        "summary": summary if staff_view else None,
        "recommendations": recommendations if staff_view else [],
    }

    if staff_view:
        try:
            payload["recent_reviews"] = await order_finding_model.get_recent_reviews_for_patient(patient_id)
        except Exception as e:
            log.warning("recent reviews skipped: %s", e)
            payload["recent_reviews"] = []

    reports = _episode_report_rows([dict(x) for x in investigations])
    payload["reports"] = reports

    active_referrals = []
    for row in referrals or []:
        r = dict(row)
        st = str(r.get("status") or "").upper()
        if st == "COMPLETED":
            continue
        for field in ("created_at", "updated_at", "appointment_date"):
            val = r.get(field)
            if val and hasattr(val, "isoformat"):
                r[field] = val.isoformat()
        sid = r.get("specialist_appointment_id")
        spec_appt = spec_appt_map.get(int(sid)) if sid else None
        active_referrals.append(_referral_payload_row(r, spec_appt))
    payload["referrals"] = active_referrals

    active_pharmacy = []
    for row in pharm_orders or []:
        r = dict(row)
        for field in ("created_at", "updated_at"):
            val = r.get(field)
            if val and hasattr(val, "isoformat"):
                r[field] = val.isoformat()
        active_pharmacy.append({
            "id": r.get("id"),
            "public_id": r.get("public_id"),
            "status": r.get("status"),
            "pharmacy_name": r.get("pharmacy_name"),
            "created_at": r.get("created_at"),
        })
    payload["pharmacy_orders"] = active_pharmacy

    if reports and str(reports[0].get("status") or "").upper() == "REPORT_AVAILABLE":
        payload["care"]["report"] = "Available"
    if inv:
        inv_st = str(inv.get("status") or "").upper()
        rrs = str(inv.get("report_review_status") or "").upper()
        if rrs == "REVIEWED":
            payload["care"]["doctor_review"] = "Completed"
        elif inv_st in {"REPORT_AVAILABLE", "REVIEWED"}:
            payload["care"]["doctor_review"] = "In progress"

    return payload


async def list_staff_journeys(actor: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Lightweight list — one/two queries. Full pipeline loads on patient click."""
    doctor_id = actor["id"] if actor.get("role") == "doctor" else None
    from app.config.db import db

    rows = []
    if doctor_id is not None:
        rows = await db.query(
            """
            WITH combined AS (
                SELECT a.user_id AS patient_id,
                       MAX(u.name) AS patient_name,
                       MAX(COALESCE(a.updated_at, a.created_at)) AS last_touch,
                       false AS has_referral,
                       false AS referral_pending
                FROM appointments a
                JOIN users u ON u.id = a.user_id
                WHERE a.doctor_id = $1
                  AND a.user_id IS NOT NULL
                  AND COALESCE(a.cancelled, false) = false
                GROUP BY a.user_id

                UNION ALL

                SELECT r.patient_id,
                       MAX(u.name) AS patient_name,
                       MAX(COALESCE(r.updated_at, r.created_at)) AS last_touch,
                       true AS has_referral,
                       BOOL_OR(UPPER(COALESCE(r.status, 'PENDING')) = 'PENDING') AS referral_pending
                FROM referrals r
                JOIN users u ON u.id = r.patient_id
                WHERE r.assigned_to = $1
                  AND UPPER(COALESCE(r.status, 'PENDING')) NOT IN (
                        'COMPLETED', 'REJECTED', 'CANCELLED'
                  )
                GROUP BY r.patient_id
            )
            SELECT patient_id,
                   MAX(patient_name) AS patient_name,
                   MAX(last_touch) AS last_touch,
                   BOOL_OR(has_referral) AS has_referral,
                   BOOL_OR(COALESCE(referral_pending, false)) AS referral_pending
            FROM combined
            GROUP BY patient_id
            ORDER BY MAX(last_touch) DESC
            LIMIT 20
            """,
            int(doctor_id),
        )
    else:
        ids = await order_finding_model.get_attention_patient_ids(
            hospital_id=actor.get("hospital_id")
        )
        out = []
        for pid in ids[:15]:
            item = await build_patient_journey(pid, staff_view=True)
            if item.get("success"):
                out.append(item)
        return out

    pids = [int(r["patient_id"]) for r in rows]
    counts = {}
    if pids:
        try:
            frows = await db.query(
                """
                SELECT patient_id,
                       COUNT(*)::int AS open_count,
                       MAX(CASE WHEN priority = 'HIGH' THEN 3
                                WHEN priority = 'MEDIUM' THEN 2
                                ELSE 1 END) AS pr
                FROM order_findings
                WHERE status = 'OPEN' AND patient_id = ANY($1::int[])
                GROUP BY patient_id
                """,
                pids,
            )
            counts = {int(r["patient_id"]): r for r in frows}
        except Exception as e:
            log.warning("finding counts skipped: %s", e)

    out = []
    for r in rows:
        pid = int(r["patient_id"])
        fc = counts.get(pid) or {}
        pr_n = int(fc.get("pr") or 0)
        priority = "HIGH" if pr_n >= 3 else "MEDIUM" if pr_n == 2 else "LOW" if pr_n == 1 else "NONE"
        out.append({
            "success": True,
            "patient_id": pid,
            "patient_name": r.get("patient_name"),
            "priority": priority,
            "has_referral": bool(r.get("has_referral")),
            "journey_status": (
                "ATTENTION_REQUIRED"
                if pr_n >= 3 or r.get("referral_pending")
                else "UPCOMING"
                if pr_n or r.get("has_referral")
                else "ON_TRACK"
            ),
        })
    out.sort(key=lambda x: PRIORITY_RANK.get(x.get("priority") or "NONE", 0), reverse=True)
    return out


async def apply_human_review(
    finding_id: int,
    actor: Dict[str, Any],
    decision: str,
    note: Optional[str] = None,
    modifications: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    finding = await order_finding_model.get_finding_by_id(finding_id)
    if not finding:
        return {"success": False, "message": "Finding not found"}

    decision = (decision or "").upper()
    if decision not in {"APPROVE", "REJECT", "MODIFY"}:
        return {"success": False, "message": "decision must be APPROVE, REJECT, or MODIFY"}

    mods = modifications or {}
    coordination_result = None
    if decision in {"APPROVE", "MODIFY"}:
        coordination_result = await _perform_approved_action(finding, mods, actor)

    review_decision = "MODIFIED" if decision == "MODIFY" else ("APPROVED" if decision == "APPROVE" else "REJECTED")
    entity = await load_entity(finding["entity_type"], finding["entity_id"])
    still = finding_still_valid(finding, entity)

    if decision == "REJECT":
        new_status = "RESOLVED"
    elif still:
        new_status = "OPEN"
    else:
        new_status = "RESOLVED"

    updated = await order_finding_model.update_finding_review(
        finding_id,
        status=new_status,
        review_decision=review_decision,
        reviewed_by=actor.get("id"),
        resolution_note=note,
    )
    await order_event_model.create_order_event(
        entity_type=finding["entity_type"],
        entity_id=finding["entity_id"],
        event_type="FINDING_REVIEWED",
        payload={
            "finding_id": finding_id,
            "decision": review_decision,
            "status": new_status,
            "actor_id": actor.get("id"),
            "actor_role": actor.get("role"),
            "comment": note,
            "ai_recommendation": finding.get("recommended_action"),
            "evidence": order_finding_model.normalize_finding(finding).get("evidence"),
            "coordination": coordination_result,
        },
    )

    if new_status == "RESOLVED" and finding.get("patient_id"):
        from app.services import fcm_service

        title = "Care journey update"
        body = (
            "Your care team dismissed a coordination alert."
            if decision == "REJECT"
            else "Your care team completed a coordination step on your journey."
        )
        await fcm_service.send_to_user(
            int(finding["patient_id"]),
            title=title,
            body=body,
            data={"type": "care_journey", "findingId": str(finding_id)},
        )

    patient_id = int(finding["patient_id"])
    agent_refresh = await _refresh_agents_after_review(patient_id)
    journey = await build_patient_journey(patient_id, staff_view=True)
    return {
        "success": True,
        "finding": order_finding_model.normalize_finding(updated or finding),
        "resolved": new_status == "RESOLVED",
        "still_valid": still,
        "coordination": coordination_result,
        "human_review": {
            "decision": review_decision,
            "reviewer_id": actor.get("id"),
            "reviewer_role": actor.get("role"),
            "comment": note,
        },
        "agent_refresh": agent_refresh,
        "journey": journey,
    }


async def _refresh_agents_after_review(patient_id: int) -> Dict[str, bool]:
    """Re-run monitoring agents and close stale findings after human review."""
    from app.services.order_monitoring_service import run_order_monitoring_cycle

    try:
        await run_order_monitoring_cycle()
    except Exception as e:
        log.warning("agent refresh after review failed: %s", e)
    try:
        await verify_and_close_stale_findings(patient_id=patient_id)
    except Exception as e:
        log.warning("stale close after review failed: %s", e)
    return {
        "investigation": True,
        "referral": True,
        "followup": True,
        "orchestrator": True,
    }


async def _perform_approved_action(finding: Dict[str, Any], mods: Dict[str, Any], actor: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Run existing MEDCLUES order updates only — no clinical interpretation."""
    ftype = (finding.get("finding_type") or "").upper()
    entity_id = int(finding["entity_id"])
    entity_type = finding["entity_type"]

    if entity_type == "investigation" and ftype == "REPORT_REVIEW_PENDING":
        updated = await investigation_model.update_investigation(
            entity_id,
            {
                "status": "REVIEWED",
                "report_review_status": "REVIEWED",
                "reviewed_at": datetime.now(),
                "reviewed_by": (actor or {}).get("id"),
            },
        )
        await order_event_model.create_order_event(
            "investigation", entity_id, "REPORT_REVIEWED",
            {"old_status": "REPORT_AVAILABLE", "new_status": "REVIEWED", "actor_role": "staff_approved"},
        )
        return {"action": "mark_report_reviewed", "ok": bool(updated)}

    if entity_type == "referral" and ftype in {"REFERRAL_APPOINTMENT_PENDING", "REFERRAL_DELAYED"}:
        appt = mods.get("appointment_date") or mods.get("appointmentDate")
        ref_row = await referral_model.get_referral_by_id(entity_id)
        patient_id = finding.get("patient_id") or (ref_row or {}).get("patient_id")
        specialist_id = (ref_row or {}).get("assigned_to")

        if appt:
            when = datetime.fromisoformat(str(appt).replace("Z", "+00:00"))
            updated = await referral_model.update_referral(
                entity_id,
                {"status": "APPOINTMENT_BOOKED", "appointment_date": when},
            )
            await order_event_model.create_order_event(
                "referral", entity_id, "STATUS_CHANGED",
                {"old_status": finding.get("entity_status"), "new_status": "APPOINTMENT_BOOKED", "actor_role": "staff_approved"},
            )
            if patient_id:
                from app.services import journey_notify

                await journey_notify.notify_patient(
                    int(patient_id),
                    "Specialist appointment scheduled",
                    f"Your specialist visit is scheduled for {when.strftime('%Y-%m-%d %H:%M')}.",
                    {"type": "referral", "referralId": str(entity_id)},
                )
            if specialist_id:
                from app.services import journey_notify

                await journey_notify.notify_doctor(
                    int(specialist_id),
                    "Referral appointment scheduled",
                    f"A specialist appointment was scheduled following staff review.",
                    {"type": "referral", "referralId": str(entity_id)},
                )
            return {"action": "book_specialist_appointment", "ok": bool(updated), "appointment_date": _iso(when)}

        from app.services import journey_notify

        patient_name = (finding.get("evidence") or {}).get("patient") if isinstance(finding.get("evidence"), dict) else None
        if patient_id:
            await journey_notify.notify_patient(
                int(patient_id),
                "Specialist appointment needed",
                "Your care team approved coordinating your specialist visit. Please book an appointment when slots are available.",
                {"type": "referral", "referralId": str(entity_id)},
            )
        if specialist_id:
            await journey_notify.notify_doctor(
                int(specialist_id),
                "Coordinate specialist appointment",
                f"Staff approved coordination for patient {patient_name or 'referral'} — please provide appointment slots.",
                {"type": "referral", "referralId": str(entity_id)},
            )
        return {"action": "coordinate_specialist_appointment", "ok": True, "notified": True}

    if entity_type == "referral" and ftype == "REFERRAL_AWAITING_SPECIALIST":
        ref_row = await referral_model.get_referral_by_id(entity_id)
        specialist_id = (ref_row or {}).get("assigned_to")
        if specialist_id:
            from app.services import journey_notify

            await journey_notify.notify_doctor(
                int(specialist_id),
                "Referral awaiting your response",
                "Staff approved a follow-up reminder for this referral. Please accept or decline.",
                {"type": "referral", "referralId": str(entity_id)},
            )
        return {"action": "remind_specialist", "ok": True}

    if entity_type == "referral" and ftype == "REFERRAL_NO_SPECIALIST":
        patient_id = finding.get("patient_id")
        if patient_id:
            from app.services import journey_notify

            await journey_notify.notify_patient(
                int(patient_id),
                "Referral coordination",
                "Your care team is assigning a specialist for your referral.",
                {"type": "referral", "referralId": str(entity_id)},
            )
        return {"action": "coordinate_specialist_assignment", "ok": True}

    if entity_type == "investigation" and ftype in {"INVESTIGATION_PENDING", "INVESTIGATION_DELAYED"}:
        if finding.get("patient_id"):
            from app.services import journey_notify

            await journey_notify.notify_patient(
                int(finding["patient_id"]),
                "Investigation update",
                "Your laboratory test is being processed. We will notify you when results are available.",
                {"type": "investigation", "investigationId": str(entity_id)},
            )
        await order_event_model.create_order_event(
            "investigation", entity_id, "COORDINATION_REMINDER",
            {"finding_type": ftype, "actor_role": "staff_approved"},
        )
        return {"action": "investigation_coordination_reminder", "ok": True}

    if entity_type == "pharmacy" and ftype in {
        "PHARMACY_ORDER_PENDING",
        "PHARMACY_PAYMENT_PENDING",
        "PHARMACY_READY_NOT_COLLECTED",
    }:
        if finding.get("patient_id"):
            from app.services import journey_notify

            bodies = {
                "PHARMACY_ORDER_PENDING": "Your pharmacy order is being processed.",
                "PHARMACY_PAYMENT_PENDING": "Please complete payment for your pharmacy order.",
                "PHARMACY_READY_NOT_COLLECTED": "Your medicines are ready for pickup or delivery.",
            }
            await journey_notify.notify_patient(
                int(finding["patient_id"]),
                "Pharmacy update",
                bodies.get(ftype, "Pharmacy order update"),
                {"type": "pharmacy", "orderId": str(entity_id)},
            )
        return {"action": "pharmacy_patient_notify", "ok": True}

    if entity_type == "appointment" and ftype in {
        "APPOINTMENT_AWAITING_CONFIRMATION",
        "APPOINTMENT_MISSED",
        "APPOINTMENT_NOT_COMPLETED",
    }:
        from app.config.db import db

        if ftype == "APPOINTMENT_AWAITING_CONFIRMATION":
            await db.execute(
                """
                UPDATE appointments
                SET lifecycle_status = 'CONFIRMED',
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = $1
                """,
                entity_id,
            )
            await order_event_model.create_order_event(
                "appointment", entity_id, "STATUS_CHANGED",
                {"new_status": "CONFIRMED", "actor_role": "staff_approved"},
            )
        if finding.get("patient_id"):
            from app.services import journey_notify

            bodies = {
                "APPOINTMENT_AWAITING_CONFIRMATION": "Your consultation appointment has been confirmed.",
                "APPOINTMENT_MISSED": "Please reschedule your missed consultation appointment.",
                "APPOINTMENT_NOT_COMPLETED": "Your consultation slot has passed — please reschedule.",
            }
            await journey_notify.notify_patient(
                int(finding["patient_id"]),
                "Appointment coordination",
                bodies.get(ftype, "Please confirm or reschedule your consultation appointment."),
                {"type": "appointment", "appointmentId": str(entity_id)},
            )
        action = "confirm_appointment" if ftype == "APPOINTMENT_AWAITING_CONFIRMATION" else "appointment_coordination_reminder"
        return {"action": action, "ok": True}

    if entity_type == "followup" and ftype in {"FOLLOWUP_UPCOMING", "FOLLOWUP_OVERDUE", "FOLLOWUP_MISSED"}:
        if mods.get("mark_completed") or mods.get("status") == "COMPLETED":
            updated = await followup_model.update_followup(entity_id, {"status": "COMPLETED", "completed_at": datetime.now()})
            await order_event_model.create_order_event(
                "followup", entity_id, "FOLLOWUP_COMPLETED",
                {"new_status": "COMPLETED", "actor_role": "staff_approved"},
            )
            return {"action": "followup_completed", "ok": bool(updated)}

        status = "REMINDED" if ftype == "FOLLOWUP_UPCOMING" else "SCHEDULED"
        payload = {"status": status, "reminded_at": datetime.now()}
        if ftype != "FOLLOWUP_UPCOMING" and mods.get("due_date"):
            payload = {"due_date": date.fromisoformat(str(mods["due_date"])[:10]), "status": "SCHEDULED"}
        updated = await followup_model.update_followup(entity_id, payload)
        await order_event_model.create_order_event(
            "followup", entity_id, "STATUS_CHANGED",
            {"new_status": payload.get("status"), "actor_role": "staff_approved"},
        )
        if finding.get("patient_id"):
            from app.services import fcm_service

            await fcm_service.send_to_user(
                int(finding["patient_id"]),
                title="Follow-up reminder",
                body="Please attend your scheduled follow-up visit.",
                data={"type": "followup", "followupId": str(entity_id)},
            )
        return {"action": "followup_reminder", "ok": bool(updated)}

    return {"action": "none", "ok": True, "note": "No automated coordination for this finding type"}
