"""Patient Journey Agent + Orchestrator.

Deterministic coordination state is computed from existing MEDCLUES tables.
The configured LLM is used only to phrase a grounded summary — never to diagnose.
"""
from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import Any, Dict, List, Optional
from zoneinfo import ZoneInfo

from app.models import (
    appointment_model,
    doctor_model,
    followup_model,
    investigation_model,
    notification_model,
    order_event_model,
    order_finding_model,
    referral_model,
    user_model,
)
from app.utils.app_logger import get_logger

log = get_logger("medclues.patient_journey")
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


def _consultation_label(appt: Optional[Dict[str, Any]]) -> str:
    if not appt:
        return "NONE"
    if appt.get("cancelled"):
        return "CANCELLED"
    if appt.get("is_completed") or str(appt.get("status") or "").lower() == "completed":
        return "COMPLETED"
    life = str(appt.get("lifecycle_status") or "").upper()
    if life in {"IN_PROGRESS", "CHECKED_IN"}:
        return "IN_CONSULTATION"
    if life in {"COMPLETED", "FOLLOWUP_AVAILABLE", "CLOSED"}:
        return "COMPLETED"
    if life in {"BOOKED", "CONFIRMED"}:
        return "SCHEDULED"
    status = str(appt.get("status") or "").lower()
    if status in {"pending", "confirmed"}:
        return "SCHEDULED"
    return life or str(appt.get("status") or "UNKNOWN").upper()


def _investigation_labels(inv: Optional[Dict[str, Any]]) -> tuple[str, str]:
    if not inv:
        return "NONE", "NONE"
    status = str(inv.get("status") or "ORDERED").upper()
    if status == "REVIEWED":
        return "COMPLETED", "REVIEWED"
    if status == "REPORT_AVAILABLE":
        return "COMPLETED", "PENDING_REVIEW"
    if status in {"TEST_PERFORMED", "SAMPLE_COLLECTED", "ACCEPTED", "ORDERED"}:
        return status, "PENDING"
    return status, "PENDING"


def _referral_labels(ref: Optional[Dict[str, Any]]) -> tuple[str, str]:
    if not ref:
        return "NONE", "NONE"
    status = str(ref.get("status") or "PENDING").upper()
    booked = bool(ref.get("appointment_date")) or status in {
        "APPOINTMENT_BOOKED",
        "SPECIALIST_CONSULTATION",
        "COMPLETED",
    }
    if status == "COMPLETED":
        return "COMPLETED", "COMPLETED"
    if booked:
        return status, "CONFIRMED"
    if status in {"PENDING", "ACCEPTED"}:
        return status, "APPOINTMENT_PENDING"
    return status, "APPOINTMENT_PENDING"


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
    return status


def finding_still_valid(finding: Dict[str, Any], entity: Optional[Dict[str, Any]]) -> bool:
    """True only if the live database row still matches the finding condition."""
    ftype = (finding.get("finding_type") or "").upper()
    message = (finding.get("message") or "").lower()
    if entity is None:
        return False
    status = str(entity.get("status") or "").upper()

    if ftype == "REPORT_REVIEW_PENDING" or "requires doctor review" in message:
        return status == "REPORT_AVAILABLE" and not entity.get("reviewed_at")
    if ftype in {"INVESTIGATION_DELAYED", "INVESTIGATION_PENDING"} or "investigation pending" in message:
        return status in {"ORDERED", "ACCEPTED", "SAMPLE_COLLECTED", "TEST_PERFORMED"}
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
    return status not in {"REVIEWED", "COMPLETED"}


async def load_entity(entity_type: str, entity_id: int) -> Optional[Dict[str, Any]]:
    if entity_type == "investigation":
        row = await investigation_model.get_investigation_by_id(entity_id)
    elif entity_type == "referral":
        row = await referral_model.get_referral_by_id(entity_id)
    elif entity_type == "followup":
        row = await followup_model.get_followup_by_id(entity_id)
    else:
        return None
    return dict(row) if row else None


async def verify_and_close_stale_findings(patient_id: Optional[int] = None) -> int:
    if patient_id is not None:
        findings = await order_finding_model.get_open_findings_by_patient(patient_id)
    else:
        findings = await order_finding_model.get_open_findings_by_role("doctor")
        extra_roles = ("lab_staff", "referral_coordinator", "appointment_coordinator")
        for role in extra_roles:
            findings.extend(await order_finding_model.get_open_findings_by_role(role))
        seen = set()
        uniq = []
        for f in findings:
            if f["id"] in seen:
                continue
            seen.add(f["id"])
            uniq.append(f)
        findings = uniq

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


def _journey_status(journey: Dict[str, str], findings: List[Dict[str, Any]]) -> str:
    if any(str(f.get("priority")) == "HIGH" for f in findings):
        return "ATTENTION_REQUIRED"
    if journey.get("followup") in {"OVERDUE", "MISSED"}:
        return "ATTENTION_REQUIRED"
    if journey.get("report") == "PENDING_REVIEW" or journey.get("specialist_appointment") == "APPOINTMENT_PENDING":
        return "ATTENTION_REQUIRED"
    if findings:
        return "ATTENTION_REQUIRED"
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
    if not ref or not ref.get("assigned_to"):
        return None
    doc = await doctor_model.get_doctor_by_id(int(ref["assigned_to"]))
    if doc:
        return doc.get("name")
    return None


async def build_patient_journey(patient_id: int, *, staff_view: bool = True) -> Dict[str, Any]:
    user = await user_model.get_user_by_id(patient_id)
    if not user:
        return {"success": False, "message": "Patient not found"}

    appointments = await appointment_model.get_appointments_by_user_id(patient_id, limit=1)
    investigations = await investigation_model.get_investigations_by_patient(patient_id)
    referrals = await referral_model.get_referrals_by_patient(patient_id)
    followups = await followup_model.get_followups_by_patient(patient_id)

    appt = dict(appointments[0]) if appointments else None
    inv = dict(_latest([dict(x) for x in investigations]) or {}) or None
    if inv == {}:
        inv = None
    ref = dict(_latest([dict(x) for x in referrals]) or {}) or None
    if ref == {}:
        ref = None
    fol = dict(_latest([dict(x) for x in followups]) or {}) or None
    if fol == {}:
        fol = None

    inv_status, report_status = _investigation_labels(inv)
    ref_status, spec_status = _referral_labels(ref)
    journey = {
        "consultation": _consultation_label(appt),
        "investigation": inv_status,
        "report": report_status,
        "referral": ref_status,
        "specialist_appointment": spec_status,
        "followup": _followup_label(fol),
    }

    open_findings = [
        order_finding_model.normalize_finding(f)
        for f in await order_finding_model.get_open_findings_by_patient(patient_id)
    ]
    open_findings = _dedupe_findings(open_findings)
    priority = _priority_from_findings(open_findings)
    journey_status = _journey_status(journey, open_findings)

    specialist = await _specialist_name(ref)
    evidence: List[Dict[str, Any]] = []
    if inv:
        evidence.append({
            "type": "investigation",
            "id": inv.get("id"),
            "test_name": inv.get("test_name"),
            "ordered": _iso(inv.get("created_at")),
            "completed": _iso(inv.get("updated_at")) if inv_status in {"COMPLETED", "REPORT_AVAILABLE", "REVIEWED"} else None,
            "report": "Available" if report_status in {"PENDING_REVIEW", "REVIEWED"} or bool(inv.get("report_url")) else "Not available",
            "reviewed": "Reviewed" if inv.get("reviewed_at") or inv_status == "REVIEWED" else "Pending",
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

    recommendations = _recommendations(open_findings)
    summary = _template_summary(journey, open_findings)
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
        "findings": open_findings if staff_view else [],
        "evidence": evidence if staff_view else [],
        "summary": summary if staff_view else None,
        "recommendations": recommendations if staff_view else [],
    }

    if not staff_view:
        notes = await notification_model.list_for_user(patient_id, limit=8)
        payload["care"] = {
            "consultation": journey["consultation"],
            "investigation": journey["investigation"],
            "report": "AVAILABLE" if report_status in {"PENDING_REVIEW", "REVIEWED"} else report_status,
            "referral": journey["referral"],
            "specialist_appointment": "CONFIRMED" if spec_status == "CONFIRMED" else spec_status,
            "followup": journey["followup"],
        }
        payload["journey_status"] = "ON_TRACK" if journey_status == "ON_TRACK" else "ACTION_NEEDED"
        payload["notifications"] = [
            {
                "id": n.get("id"),
                "title": n.get("title"),
                "body": n.get("body"),
                "created_at": _iso(n.get("created_at")),
            }
            for n in notes
        ]
        payload.pop("findings", None)
        payload.pop("recommendations", None)
        payload.pop("summary", None)
        payload.pop("evidence", None)
        payload.pop("priority", None)
    return payload


async def list_staff_journeys(actor: Dict[str, Any]) -> List[Dict[str, Any]]:
    doctor_id = actor["id"] if actor.get("role") == "doctor" else None
    hospital_id = actor.get("hospital_id") if actor.get("role") != "doctor" else None
    ids = await order_finding_model.get_attention_patient_ids(doctor_id=doctor_id, hospital_id=hospital_id)
    out = []
    for pid in ids:
        item = await build_patient_journey(pid, staff_view=True)
        if item.get("success"):
            out.append(item)
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
        coordination_result = await _perform_approved_action(finding, mods)

    review_decision = "MODIFIED" if decision == "MODIFY" else ("APPROVED" if decision == "APPROVE" else "REJECTED")
    entity = await load_entity(finding["entity_type"], finding["entity_id"])
    still = finding_still_valid(finding, entity)
    new_status = "OPEN" if decision == "REJECT" or still else "RESOLVED"

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
            "actor_role": actor.get("role"),
            "coordination": coordination_result,
        },
    )

    if new_status == "RESOLVED" and finding.get("patient_id"):
        from app.services import fcm_service

        await fcm_service.send_to_user(
            int(finding["patient_id"]),
            title="Care journey update",
            body="Your care team completed a coordination step on your journey.",
            data={"type": "care_journey", "findingId": str(finding_id)},
        )

    journey = await build_patient_journey(int(finding["patient_id"]), staff_view=True)
    return {
        "success": True,
        "finding": order_finding_model.normalize_finding(updated or finding),
        "resolved": new_status == "RESOLVED",
        "still_valid": still,
        "coordination": coordination_result,
        "journey": journey,
    }


async def _perform_approved_action(finding: Dict[str, Any], mods: Dict[str, Any]) -> Dict[str, Any]:
    """Run existing MEDCLUES order updates only — no clinical interpretation."""
    ftype = (finding.get("finding_type") or "").upper()
    entity_id = int(finding["entity_id"])
    entity_type = finding["entity_type"]

    if entity_type == "investigation" and ftype == "REPORT_REVIEW_PENDING":
        updated = await investigation_model.update_investigation(
            entity_id, {"status": "REVIEWED", "reviewed_at": datetime.now()}
        )
        await order_event_model.create_order_event(
            "investigation", entity_id, "STATUS_CHANGED",
            {"old_status": "REPORT_AVAILABLE", "new_status": "REVIEWED", "actor_role": "staff_approved"},
        )
        return {"action": "mark_report_reviewed", "ok": bool(updated)}

    if entity_type == "referral" and ftype in {"REFERRAL_APPOINTMENT_PENDING", "REFERRAL_DELAYED"}:
        appt = mods.get("appointment_date") or mods.get("appointmentDate")
        if appt:
            when = datetime.fromisoformat(str(appt).replace("Z", "+00:00"))
        else:
            when = datetime.now(IST) + timedelta(days=1)
        updated = await referral_model.update_referral(
            entity_id,
            {"status": "APPOINTMENT_BOOKED", "appointment_date": when},
        )
        await order_event_model.create_order_event(
            "referral", entity_id, "STATUS_CHANGED",
            {"old_status": finding.get("entity_status"), "new_status": "APPOINTMENT_BOOKED", "actor_role": "staff_approved"},
        )
        if finding.get("patient_id"):
            from app.services import fcm_service

            await fcm_service.send_to_user(
                int(finding["patient_id"]),
                title="Specialist appointment scheduled",
                body=f"Your specialist visit is scheduled for {when.strftime('%Y-%m-%d %H:%M')}.",
                data={"type": "referral", "referralId": str(entity_id)},
            )
        return {"action": "book_specialist_appointment", "ok": bool(updated), "appointment_date": _iso(when)}

    if entity_type == "followup" and ftype in {"FOLLOWUP_UPCOMING", "FOLLOWUP_OVERDUE", "FOLLOWUP_MISSED"}:
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
