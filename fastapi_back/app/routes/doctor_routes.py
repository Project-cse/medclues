from fastapi import APIRouter, Depends, Request, UploadFile, File, Form
from app.controllers import doctor_controller, consultation_controller, doctor_slot_controller
from app.middleware.auth import auth_doctor
from app.utils.auth_response import build_auth_response
from app.models import doctor_model
from app.utils.formatters import format_doctor
from typing import Optional

router = APIRouter(prefix="/api/doctor", tags=["Doctor"])

@router.post("/login")
async def login_doctor(req: Request):
    body = await req.json()
    result = await doctor_controller.login_doctor(body)
    return build_auth_response(result, "doctor", req)

@router.get("/appointments")
async def appointments_doctor(doc_id: int = Depends(auth_doctor)):
    return await doctor_controller.appointments_doctor(doc_id)

@router.post("/cancel-appointment")
async def appointment_cancel(req: Request, doc_id: int = Depends(auth_doctor)):
    body = await req.json()
    return await doctor_controller.appointment_cancel(doc_id, body.get('appointmentId'))

@router.post("/reject-appointment")
async def appointment_reject(req: Request, doc_id: int = Depends(auth_doctor)):
    body = await req.json()
    return await doctor_controller.appointment_cancel(doc_id, body.get('appointmentId'), body.get('reason'))

@router.post("/complete-appointment")
async def appointment_complete(req: Request, doc_id: int = Depends(auth_doctor)):
    body = await req.json()
    return await doctor_controller.appointment_complete(doc_id, body.get('appointmentId'))

@router.get("/list")
async def doctor_list(hospitalId: Optional[int] = None):
    return await doctor_controller.doctor_list(hospitalId)

@router.get("/change-availability")
async def change_availability(doc_id: int = Depends(auth_doctor)):
    return await doctor_controller.change_availability(doc_id)

@router.get("/profile")
async def doctor_profile(doc_id: int = Depends(auth_doctor)):
    return await doctor_controller.doctor_profile(doc_id)

@router.post("/update-profile")
async def update_profile(
    fees: Optional[str] = Form(None),
    about: Optional[str] = Form(None),
    address: Optional[str] = Form(None),
    available: Optional[str] = Form(None),
    status: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    doc_id: int = Depends(auth_doctor)
):
    form_data = {
        "fees": fees,
        "about": about,
        "address": address,
        "available": available,
        "status": status
    }
    return await doctor_controller.update_doctor_profile(doc_id, form_data, image)

@router.get("/dashboard")
async def doctor_dashboard(doc_id: int = Depends(auth_doctor)):
    return await doctor_controller.doctor_dashboard(doc_id)

@router.get("/queue-status")
async def get_queue_status(req: Request, doc_id: int = Depends(auth_doctor)):
    slot_date = req.query_params.get('slotDate')
    return await doctor_controller.get_queue_status(doc_id, slot_date)

@router.post("/start-consultation")
async def start_consultation(req: Request, doc_id: int = Depends(auth_doctor)):
    body = await req.json()
    return await doctor_controller.start_consultation(doc_id, body.get('appointmentId'))

@router.post("/end-consultation")
async def end_consultation(req: Request, doc_id: int = Depends(auth_doctor)):
    body = await req.json()
    return await doctor_controller.end_consultation(doc_id, body)

@router.get("/consultations")
async def doctor_consultations(doc_id: int = Depends(auth_doctor)):
    return await doctor_controller.doctor_consultations(doc_id)

@router.get("/consultation/{consultationId}")
async def get_consultation_details(consultationId: int, doc_id: int = Depends(auth_doctor)):
    return await doctor_controller.get_consultation_details(doc_id, consultationId)

@router.get("/patient-records/{appointmentId}")
async def get_patient_records(appointmentId: int, doc_id: int = Depends(auth_doctor)):
    from app.controllers import health_record_controller
    return await health_record_controller.get_patient_records_for_doctor(doc_id, appointmentId)

@router.post("/patient-records/{recordId}/viewed")
async def mark_record_as_viewed(recordId: int, doc_id: int = Depends(auth_doctor)):
    from app.controllers import health_record_controller
    return await health_record_controller.mark_record_as_viewed(doc_id, recordId)

@router.post("/appointments/{appointmentId}/agora-token")
async def doctor_agora_token(appointmentId: int, doc_id: int = Depends(auth_doctor)):
    return await consultation_controller.get_agora_token_for_doctor_appointment(doc_id, appointmentId)

@router.get("/appointments/{appointmentId}/video-call-status")
async def doctor_video_call_status(appointmentId: int, doc_id: int = Depends(auth_doctor)):
    return await consultation_controller.get_video_call_status_for_doctor(doc_id, appointmentId)

@router.post("/appointments/{appointmentId}/sync-call-timer")
async def doctor_sync_call_timer(appointmentId: int, doc_id: int = Depends(auth_doctor)):
    return await consultation_controller.sync_call_timer_for_doctor(doc_id, appointmentId)

@router.post("/appointments/{appointmentId}/end-video-call")
async def doctor_end_video_call(appointmentId: int, req: Request, doc_id: int = Depends(auth_doctor)):
    body = {}
    if req.headers.get('content-type', '').startswith('application/json'):
        try:
            body = await req.json()
        except Exception:
            body = {}
    return await consultation_controller.end_video_call_for_doctor(doc_id, appointmentId, body)

@router.get("/{doctor_id}/slots")
async def get_doctor_schedule_slots(doctor_id: str, mode: str = "offline"):
    from fastapi.responses import JSONResponse

    data = await doctor_slot_controller.get_doctor_slots(doctor_id, mode)
    return JSONResponse(
        content=data,
        headers={"Cache-Control": "no-store, no-cache, must-revalidate"},
    )

# Public doctor details endpoint. Supports numeric ids and embedded ids like "emb_56".
@router.get("/{docId}")
async def get_doctor_by_id(docId: str):
    doctor = await doctor_model.get_doctor_by_id(docId)
    if not doctor:
        return {"success": False, "message": "Doctor not found"}
    return {"success": True, "doctor": format_doctor(doctor)}
