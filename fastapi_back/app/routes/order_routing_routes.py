from fastapi import APIRouter, Depends, Request, HTTPException
from typing import Optional, Dict, Any, List
from jose import jwt
from datetime import date, datetime

from app.config.config import settings
from app.config.db import db
from app.models import (
    investigation_model,
    referral_model,
    followup_model,
    order_event_model,
    order_finding_model,
    doctor_model,
)
from app.middleware.auth import auth_doctor
from app.utils.order_helpers import is_investigation_pending_review

router = APIRouter(prefix="/api", tags=["Order Routing & Queues"])

# Unified Staff Auth Dependency
async def auth_staff_role(request: Request) -> Dict[str, Any]:
    # Look for headers
    token_str = (
        request.headers.get("token")
        or request.headers.get("Token")
        or request.headers.get("dtoken")
        or request.headers.get("dToken")
        or request.headers.get("rectoken")
        or request.headers.get("deantoken")
        or request.headers.get("Authorization")
    )
    
    if token_str and token_str.startswith("Bearer "):
        token_str = token_str[7:]
        
    if not token_str:
        raise HTTPException(status_code=401, detail="Authentication token missing")
        
    try:
        secret = settings.JWT_SECRET.strip('"').strip("'")
        payload = jwt.decode(token_str, secret, algorithms=["HS256"])
        role = (payload.get("role") or "patient").strip().lower()
        if role == "patient":
            raise HTTPException(status_code=403, detail="Staff access required")
        
        # Get id and hospital_id
        actor_id = payload.get("id") or payload.get("userId")
        hospital_id = payload.get("hospital_id")
        
        return {
            "id": int(actor_id) if actor_id is not None else None,
            "role": role,
            "hospital_id": int(hospital_id) if hospital_id is not None else None,
        }
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

async def get_hospital_id_for_actor(actor: Dict[str, Any]) -> Optional[int]:
    if actor["role"] == "doctor" and actor["id"] is not None:
        doc = await doctor_model.get_doctor_by_id(actor["id"])
        if doc:
            try:
                return int(doc.get("hospital_id")) if doc.get("hospital_id") is not None else None
            except (ValueError, TypeError):
                return None
    return actor.get("hospital_id")


# ─── ORDER CREATION ENDPOINTS (Doctors Only) ───────────────────────────

@router.post("/investigations")
async def create_investigation_endpoint(req: Request, doc_id: int = Depends(auth_doctor)):
    body = await req.json()
    test_name = body.get("testName") or body.get("test_name")
    patient_id = body.get("patientId") or body.get("patient_id")
    priority = body.get("priority", "ROUTINE")
    notes = body.get("notes")

    if not test_name or not patient_id:
        raise HTTPException(status_code=400, detail="test_name and patient_id are required")

    # Fetch doctor details to resolve hospital_id
    doc = await doctor_model.get_doctor_by_id(doc_id)
    hospital_id = None
    if doc:
        try:
            hospital_id = int(doc.get("hospital_id")) if doc.get("hospital_id") is not None else None
        except (ValueError, TypeError):
            hospital_id = None

    order = await investigation_model.create_investigation(
        patient_id=int(patient_id),
        ordered_by=doc_id,
        hospital_id=hospital_id,
        test_name=test_name,
        priority=priority,
        notes=notes,
    )

    if not order:
        raise HTTPException(status_code=500, detail="Failed to create investigation order")

    # Emit event
    await order_event_model.create_order_event(
        entity_type="investigation",
        entity_id=order["id"],
        event_type="ORDER_CREATED",
        payload={"status": "ORDERED", "test_name": test_name, "priority": priority},
    )

    return {"success": True, "investigation": dict(order)}


@router.post("/referrals")
async def create_referral_endpoint(req: Request, doc_id: int = Depends(auth_doctor)):
    body = await req.json()
    patient_id = body.get("patientId") or body.get("patient_id")
    to_dept = body.get("toDept") or body.get("to_dept")
    from_dept = body.get("fromDept") or body.get("from_dept")
    reason = body.get("reason")
    notes = body.get("notes")

    if not to_dept or not reason or not patient_id:
        raise HTTPException(status_code=400, detail="patient_id, to_dept, and reason are required")

    doc = await doctor_model.get_doctor_by_id(doc_id)
    hospital_id = None
    if doc:
        try:
            hospital_id = int(doc.get("hospital_id")) if doc.get("hospital_id") is not None else None
        except (ValueError, TypeError):
            hospital_id = None

    order = await referral_model.create_referral(
        patient_id=int(patient_id),
        ordered_by=doc_id,
        hospital_id=hospital_id,
        from_dept=from_dept,
        to_dept=to_dept,
        reason=reason,
        notes=notes,
    )

    if not order:
        raise HTTPException(status_code=500, detail="Failed to create referral order")

    await order_event_model.create_order_event(
        entity_type="referral",
        entity_id=order["id"],
        event_type="ORDER_CREATED",
        payload={"status": "PENDING", "to_dept": to_dept, "from_dept": from_dept},
    )

    return {"success": True, "referral": dict(order)}


@router.post("/followups")
async def create_followup_endpoint(req: Request, doc_id: int = Depends(auth_doctor)):
    body = await req.json()
    patient_id = body.get("patientId") or body.get("patient_id")
    due_date_str = body.get("dueDate") or body.get("due_date")
    reason = body.get("reason")
    notes = body.get("notes")
    instructions = body.get("instructions")

    if not patient_id or not due_date_str:
        raise HTTPException(status_code=400, detail="patient_id and due_date are required")

    if not reason and not instructions:
        raise HTTPException(status_code=400, detail="reason is required")

    try:
        due_date = date.fromisoformat(due_date_str)
    except ValueError:
        raise HTTPException(status_code=400, detail="due_date must be in YYYY-MM-DD format")

    doc = await doctor_model.get_doctor_by_id(doc_id)
    hospital_id = None
    if doc:
        try:
            hospital_id = int(doc.get("hospital_id")) if doc.get("hospital_id") is not None else None
        except (ValueError, TypeError):
            hospital_id = None

    primary_reason = reason or instructions

    order = await followup_model.create_followup(
        patient_id=int(patient_id),
        ordered_by=doc_id,
        hospital_id=hospital_id,
        due_date=due_date,
        reason=primary_reason,
        notes=notes,
        instructions=primary_reason,
    )

    if not order:
        raise HTTPException(status_code=500, detail="Failed to create followup order")

    await order_event_model.create_order_event(
        entity_type="followup",
        entity_id=order["id"],
        event_type="ORDER_CREATED",
        payload={"status": "SCHEDULED", "due_date": due_date_str},
    )

    return {"success": True, "followup": dict(order)}


# ─── QUEUE ENDPOINTS (Role / Hospital Guarded) ─────────────────────────

@router.get("/lab/queue")
async def get_lab_queue_endpoint(
    status: Optional[str] = None,
    actor: Dict[str, Any] = Depends(auth_staff_role),
):
    hospital_id = await get_hospital_id_for_actor(actor)
    queue = await investigation_model.get_lab_queue(hospital_id=hospital_id, status=status)
    return {"success": True, "queue": [dict(x) for x in queue]}


@router.get("/referrals/queue")
async def get_referrals_queue_endpoint(actor: Dict[str, Any] = Depends(auth_staff_role)):
    hospital_id = await get_hospital_id_for_actor(actor)
    queue = await referral_model.get_referrals_queue(hospital_id=hospital_id)
    return {"success": True, "queue": [dict(x) for x in queue]}


@router.get("/appointments/queue")
async def get_appointments_queue_endpoint(actor: Dict[str, Any] = Depends(auth_staff_role)):
    hospital_id = await get_hospital_id_for_actor(actor)
    queue = await followup_model.get_followups_queue(hospital_id=hospital_id)
    return {"success": True, "queue": [dict(x) for x in queue]}


# ─── STATUS UPDATE PATCH ENDPOINTS ───────────────────────────────────────

@router.patch("/investigations/{id}")
async def update_investigation_endpoint(id: int, req: Request, actor: Dict[str, Any] = Depends(auth_staff_role)):
    body = await req.json()
    status = body.get("status")
    assigned_to = body.get("assigned_to") or body.get("assignedTo")
    report_url = body.get("report_url") or body.get("reportUrl")

    order = await investigation_model.get_investigation_by_id(id)
    if not order:
        raise HTTPException(status_code=404, detail="Investigation order not found")

    old_status = order["status"]
    update_data: Dict[str, Any] = {}
    if status:
        update_data["status"] = status
        if status == "REVIEWED":
            update_data["reviewed_at"] = datetime.now()
    if assigned_to:
        update_data["assigned_to"] = int(assigned_to)
    if report_url:
        update_data["report_url"] = report_url

    updated = await investigation_model.update_investigation(id, update_data)

    # Log status event
    if status and status != old_status:
        await order_event_model.create_order_event(
            entity_type="investigation",
            entity_id=id,
            event_type="STATUS_CHANGED",
            payload={"old_status": old_status, "new_status": status, "actor_role": actor["role"]},
        )

    return {"success": True, "investigation": dict(updated)}


@router.patch("/referrals/{id}")
async def update_referral_endpoint(id: int, req: Request, actor: Dict[str, Any] = Depends(auth_staff_role)):
    body = await req.json()
    status = body.get("status")
    assigned_to = body.get("assigned_to") or body.get("assignedTo")
    appointment_date_str = body.get("appointment_date") or body.get("appointmentDate")
    notes = body.get("notes")

    order = await referral_model.get_referral_by_id(id)
    if not order:
        raise HTTPException(status_code=404, detail="Referral order not found")

    old_status = order["status"]
    update_data: Dict[str, Any] = {}
    if status:
        update_data["status"] = status
    if assigned_to:
        update_data["assigned_to"] = int(assigned_to)
    if appointment_date_str:
        update_data["appointment_date"] = datetime.fromisoformat(appointment_date_str)
    if notes:
        update_data["notes"] = notes

    updated = await referral_model.update_referral(id, update_data)

    if status and status != old_status:
        await order_event_model.create_order_event(
            entity_type="referral",
            entity_id=id,
            event_type="STATUS_CHANGED",
            payload={"old_status": old_status, "new_status": status, "actor_role": actor["role"]},
        )

    return {"success": True, "referral": dict(updated)}


@router.patch("/followups/{id}")
async def update_followup_endpoint(id: int, req: Request, actor: Dict[str, Any] = Depends(auth_staff_role)):
    body = await req.json()
    status = body.get("status")
    assigned_to = body.get("assigned_to") or body.get("assignedTo")

    order = await followup_model.get_followup_by_id(id)
    if not order:
        raise HTTPException(status_code=404, detail="Followup order not found")

    old_status = order["status"]
    update_data: Dict[str, Any] = {}
    if status:
        update_data["status"] = status
        if status == "COMPLETED":
            update_data["completed_at"] = datetime.now()
        elif status == "REMINDED":
            update_data["reminded_at"] = datetime.now()
    if assigned_to:
        update_data["assigned_to"] = int(assigned_to)

    updated = await followup_model.update_followup(id, update_data)

    if status and status != old_status:
        await order_event_model.create_order_event(
            entity_type="followup",
            entity_id=id,
            event_type="STATUS_CHANGED",
            payload={"old_status": old_status, "new_status": status, "actor_role": actor["role"]},
        )

    return {"success": True, "followup": dict(updated)}


@router.get("/patients/{patient_id}/orders")
async def get_patient_orders_endpoint(
    patient_id: int,
    scope: str = "doctor",
    actor: Dict[str, Any] = Depends(auth_staff_role)
):
    params = [int(patient_id)]
    doctor_clause = ""
    if scope == "doctor" and actor["role"] == "doctor":
        doctor_clause = " AND ordered_by = $2"
        params.append(actor["id"])

    # Query investigations
    inv_sql = f"SELECT *, 'investigation' as type FROM investigations WHERE patient_id = $1{doctor_clause}"
    inv_rows = await db.fetch_all(inv_sql, *params)
    
    # Enrich investigations with needsReview boolean using our Phase 3 helper
    enriched_invs = []
    for inv in inv_rows:
        inv_dict = dict(inv)
        inv_dict["needsReview"] = is_investigation_pending_review(inv_dict)
        enriched_invs.append(inv_dict)

    # Query referrals
    ref_sql = f"SELECT *, 'referral' as type FROM referrals WHERE patient_id = $1{doctor_clause}"
    ref_rows = await db.fetch_all(ref_sql, *params)

    # Query followups
    fol_sql = f"SELECT *, 'followup' as type FROM followups WHERE patient_id = $1{doctor_clause}"
    fol_rows = await db.fetch_all(fol_sql, *params)

    # Combine all
    all_orders = enriched_invs + [dict(x) for x in ref_rows] + [dict(x) for x in fol_rows]
    
    # Format all datetimes/dates for json responses
    for item in all_orders:
        for field in ("created_at", "updated_at", "reviewed_at", "appointment_date", "reminded_at", "completed_at"):
            val = item.get(field)
            if val:
                item[field] = val.isoformat() if hasattr(val, "isoformat") else str(val)
        dd = item.get("due_date")
        if dd:
            item["due_date"] = dd.isoformat() if hasattr(dd, "isoformat") else str(dd)

    # Sort combined list by created_at DESC
    all_orders.sort(key=lambda x: x["created_at"], reverse=True)

    return {"success": True, "orders": all_orders}


# ─── FINDINGS & ALERTS ENDPOINTS ────────────────────────────────────────

@router.get("/findings")
async def get_findings_endpoint(
    patient_id: Optional[int] = None,
    assigned_role: Optional[str] = None,
    doctor_id: Optional[int] = None,
    actor: Dict[str, Any] = Depends(auth_staff_role)
):
    if patient_id is not None:
        findings = await order_finding_model.get_findings_by_patient(int(patient_id))
    elif doctor_id is not None:
        findings = await order_finding_model.get_open_findings_for_doctor(int(doctor_id))
    elif assigned_role is not None:
        findings = await order_finding_model.get_open_findings_by_role(assigned_role)
    else:
        # Default fallback: return all open findings for the actor's role
        findings = await order_finding_model.get_open_findings_by_role(actor["role"])
        
    return {"success": True, "findings": [dict(x) for x in findings]}


@router.patch("/findings/{id}/resolve")
async def resolve_finding_endpoint(id: int, req: Request, actor: Dict[str, Any] = Depends(auth_staff_role)):
    body = await req.json()
    status = body.get("status", "RESOLVED")

    finding = await order_finding_model.get_finding_by_id(id)
    if not finding:
        raise HTTPException(status_code=404, detail="Finding not found")

    from app.services import patient_journey_service

    entity = await patient_journey_service.load_entity(finding["entity_type"], finding["entity_id"])
    if status == "RESOLVED" and patient_journey_service.finding_still_valid(finding, entity):
        raise HTTPException(
            status_code=409,
            detail="Finding is still valid against current database state. Approve a coordination action or wait until the workflow step is done.",
        )

    updated = await order_finding_model.update_finding_status(id, status)

    await order_event_model.create_order_event(
        entity_type=finding["entity_type"],
        entity_id=finding["entity_id"],
        event_type="FINDING_RESOLVED",
        payload={"finding_id": id, "status": status, "actor_role": actor["role"]},
    )

    return {"success": True, "finding": dict(updated)}

