import io
from typing import List, Optional, Union
from fastapi import APIRouter, Depends, Request, UploadFile, File, Form
from fastapi.responses import JSONResponse, StreamingResponse
from app.controllers import user_controller
from app.middleware.auth import auth_user
from app.middleware.rate_limit import rate_limit_dependency
from app.utils.auth_response import build_auth_response

router = APIRouter(prefix="/api/user", tags=["User"])

_login_limit = rate_limit_dependency("user_login", max_calls=30, window_seconds=3600)


def _client_ip(request: Request) -> str | None:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    if request.client:
        return request.client.host
    return None

@router.post("/register")
async def register_user(req: Request):
    from app.schemas.auth import RegisterRequest
    from app.utils.validation import validate_body

    body = await req.json()
    parsed = validate_body(RegisterRequest, body)
    if hasattr(parsed, "status_code"):
        return parsed
    result = await user_controller.register_user(parsed.model_dump())
    return build_auth_response(result, "patient", req)

@router.post("/login")
async def login_user(req: Request, _: None = Depends(_login_limit)):
    from app.schemas.auth import LoginRequest
    from app.utils.validation import validate_body

    body = await req.json()
    parsed = validate_body(LoginRequest, body)
    if hasattr(parsed, "status_code"):
        return parsed
    result = await user_controller.login_user(parsed.model_dump())
    return build_auth_response(result, "patient", req)

@router.post("/social-login")
async def social_login(req: Request):
    body = await req.json()
    result = await user_controller.social_login(body)
    return build_auth_response(result, "patient", req)

@router.get("/get-profile")
async def get_profile(user_id: int = Depends(auth_user)):
    return await user_controller.get_profile(user_id)

@router.patch("/profile")
async def patch_profile(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    return await user_controller.patch_profile(user_id, body)


@router.patch("/onboarding")
async def patch_onboarding(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    return await user_controller.patch_onboarding(user_id, body)


@router.post("/update-profile")
async def update_profile(
    name: Optional[str] = Form(None),
    phone: Optional[str] = Form(None),
    address: Optional[str] = Form(None),
    dob: Optional[str] = Form(None),
    gender: Optional[str] = Form(None),
    bloodGroup: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    user_id: int = Depends(auth_user)
):
    form_data = {}
    if name is not None:
        form_data["name"] = name
    if phone is not None:
        form_data["phone"] = phone
    if address is not None:
        form_data["address"] = address
    if dob is not None:
        form_data["dob"] = dob
    if gender is not None:
        form_data["gender"] = gender
    if bloodGroup is not None:
        form_data["bloodGroup"] = bloodGroup
    return await user_controller.update_profile(user_id, form_data, image)

@router.post("/book-appointment")
async def book_appointment(
    docId: str = Form(...),
    slotDate: str = Form(...),
    slotTime: str = Form(...),
    symptoms: str = Form("[]"),
    paymentMethod: str = Form("payOnVisit"),
    mode: Optional[str] = Form(None),
    slotId: Optional[str] = Form(None),
    slotType: Optional[str] = Form(None),
    actualPatient: Optional[str] = Form(None),
    hospitalName: Optional[str] = Form(None),
    location: Optional[str] = Form(None),
    prescription: Optional[UploadFile] = File(None),
    user_id: int = Depends(auth_user)
):
    try:
        import json
        body = {
            "docId": docId,
            "slotDate": slotDate,
            "slotTime": slotTime,
            "symptoms": json.loads(symptoms) if symptoms and symptoms != 'undefined' else [],
            "paymentMethod": paymentMethod,
            "mode": mode,
            "slotId": int(slotId) if slotId and str(slotId).isdigit() else None,
            "slotType": slotType,
            "hospitalName": hospitalName,
            "location": location,
            "actualPatient": json.loads(actualPatient) if actualPatient and actualPatient != 'undefined' and actualPatient != 'null' else {"isSelf": True}
        }
        return await user_controller.book_appointment(user_id, body, prescription)
    except Exception as e:
        return {"success": False, "message": f"Invalid request data: {str(e)}"}

@router.get("/appointments")
async def list_appointments(
    user_id: int = Depends(auth_user),
    limit: int | None = None,
    offset: int = 0,
):
    from app.utils.pagination import parse_pagination

    lim, off = parse_pagination(limit, offset)
    return await user_controller.list_appointments(user_id, limit=lim, offset=off)

@router.post("/cancel-appointment")
async def cancel_appointment(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    return await user_controller.cancel_appointment(user_id, body.get('appointmentId'))

@router.post("/payment-razorpay")
async def payment_razorpay(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    return await user_controller.payment_razorpay(body.get('appointmentId'))

@router.post("/verify-razorpay")
async def verify_razorpay(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    return await user_controller.verify_razorpay(body)

# camelCase alias - used by frontend
@router.post("/verifyRazorpay")
async def verify_razorpay_alias(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    return await user_controller.verify_razorpay(body)

# Health Records - accessible under /api/user/health-records (frontend uses this path)
@router.get("/health-records")
async def get_user_health_records(req: Request, user_id: int = Depends(auth_user)):
    from app.controllers import health_record_controller
    params = dict(req.query_params)
    return await health_record_controller.get_health_records(user_id, params)

@router.post("/health-records")
async def create_user_health_record(
    record_type: str = Form(None),
    title: str = Form(None),
    description: str = Form(None),
    doctor_name: str = Form(None),
    doc_id: Optional[int] = Form(None),
    appointment_id: Optional[int] = Form(None),
    date_str: str = Form(None),
    tags: str = Form(None),
    is_important: bool = Form(False),
    files: List[UploadFile] = File([]),
    user_id: int = Depends(auth_user)
):
    from app.controllers import health_record_controller
    return await health_record_controller.create_health_record(
        user_id, record_type or 'general', title, description, doctor_name, doc_id,
        appointment_id, date_str, tags, is_important, files
    )

@router.delete("/health-records/{record_id}")
async def delete_user_health_record(record_id: int, user_id: int = Depends(auth_user)):
    from app.controllers import health_record_controller
    return await health_record_controller.delete_health_record(user_id, record_id)

@router.get("/health-records/{record_id}/view-url")
async def get_health_record_view_url(
    req: Request,
    record_id: int,
    fileIndex: int = 0,
    user_id: int = Depends(auth_user),
):
    from app.controllers import health_record_controller
    return await health_record_controller.get_record_file_view_url(
        user_id,
        record_id,
        fileIndex,
        ip_address=_client_ip(req),
        user_agent=req.headers.get("User-Agent"),
    )

@router.get("/health-records/{record_id}/file")
async def stream_health_record_file(
    req: Request,
    record_id: int,
    fileIndex: int = 0,
    user_id: int = Depends(auth_user),
):
    from app.controllers import health_record_controller
    result = await health_record_controller.stream_record_file(
        user_id,
        record_id,
        fileIndex,
        ip_address=_client_ip(req),
        user_agent=req.headers.get("User-Agent"),
    )
    if not result.get("success"):
        status = 404 if "not found" in (result.get("message") or "").lower() else 502
        return JSONResponse(status_code=status, content=result)
    filename = result.get("fileName") or "report.pdf"
    safe_name = "".join(c if c.isalnum() or c in "._-" else "_" for c in filename)
    return StreamingResponse(
        io.BytesIO(result["content"]),
        media_type=result.get("contentType") or "application/pdf",
        headers={
            "Content-Disposition": f'inline; filename="{safe_name}"',
            "Cache-Control": "private, max-age=300",
        },
    )


@router.post("/forgot-password")
async def forgot_password(req: Request):
    body = await req.json()
    return await user_controller.forgot_password(body.get('email'))

@router.post("/reset-password")
async def reset_password(req: Request):
    body = await req.json()
    return await user_controller.reset_password(body)

# Public appointment verification (QR)
@router.get("/appointment/verify/{id}")
async def verify_appointment(id: int):
    return await user_controller.verify_appointment(id)


@router.get("/appointment/by-booking/{booking_id}")
async def appointment_by_booking_id(booking_id: str):
    """Alias for staff lookup by Booking ID (same as GET /api/appointments/{booking_id})."""
    return await user_controller.get_appointment_by_booking_id(booking_id)

# Public contact form
@router.post("/contact")
async def send_contact(req: Request):
    body = await req.json()
    return await user_controller.send_contact_message(body)

# Saved Profiles
@router.get("/saved-profiles")
async def get_saved_profiles(user_id: int = Depends(auth_user)):
    return await user_controller.get_saved_profiles(user_id)

@router.post("/save-profile")
async def save_profile(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    return await user_controller.save_profile(user_id, body)

# Payments (PayU & UPI)
@router.post("/payment-payu/init")
async def init_payu(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    return await user_controller.init_payu_payment(user_id, body)

@router.get("/payment/merchant-upi")
async def get_merchant_upi(user_id: int = Depends(auth_user)):
    return await user_controller.get_merchant_upi()

# Queue & Status
@router.get("/queue-status")
async def get_queue_status(docId: str, slotDate: str, user_id: int = Depends(auth_user)):
    return await user_controller.get_queue_status(docId, slotDate)

@router.get("/doctor-status")
async def get_doctor_status(docId: str):
    return await user_controller.get_doctor_status(docId)

@router.post("/mark-alerted")
async def mark_alerted(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    return await user_controller.mark_alerted(body.get('appointmentId'))

# Emergency Contacts
@router.get("/emergency-contacts")
async def get_emergency_contacts(user_id: int = Depends(auth_user)):
    return await user_controller.get_emergency_contacts(user_id)

@router.post("/emergency-contacts/add")
async def add_emergency_contact(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    return await user_controller.add_emergency_contact(user_id, body)

@router.post("/emergency-contacts/update")
async def update_emergency_contact(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    contact_id = body.get('contactId')
    if not contact_id:
        return {"success": False, "message": "contactId is required"}
    return await user_controller.update_emergency_contact(user_id, int(contact_id), body)

@router.post("/emergency-contacts/delete")
async def delete_emergency_contact(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    contact_id = body.get('contactId')
    if not contact_id:
        return {"success": False, "message": "contactId is required"}
    return await user_controller.delete_emergency_contact(user_id, int(contact_id))

# Video Consultation
from app.controllers import consultation_controller

@router.get("/video-consult-doctors")
async def get_video_consult_doctors(lat: float = None, lng: float = None, distance: str = 'all'):
    return await consultation_controller.get_video_consult_doctors(lat, lng, distance)

@router.post("/consultation/create")
async def create_consultation(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    return await consultation_controller.create_consultation(user_id, body)

@router.get("/consultations")
async def get_user_consultations(user_id: int = Depends(auth_user)):
    return await consultation_controller.get_user_consultations(user_id)

@router.get("/consultation/{consultationId}")
async def get_consultation(consultationId: int, user_id: int = Depends(auth_user)):
    return await consultation_controller.get_consultation(consultationId)

@router.post("/appointments/{appointmentId}/agora-token")
async def get_appointment_agora_token(appointmentId: int, user_id: int = Depends(auth_user)):
    return await consultation_controller.get_agora_token_for_appointment(user_id, appointmentId)

@router.get("/appointments/{appointmentId}/video-call-status")
async def user_video_call_status(appointmentId: int, user_id: int = Depends(auth_user)):
    return await consultation_controller.get_video_call_status_for_user(user_id, appointmentId)

@router.post("/appointments/{appointmentId}/sync-call-timer")
async def user_sync_call_timer(appointmentId: int, user_id: int = Depends(auth_user)):
    return await consultation_controller.sync_call_timer_for_user(user_id, appointmentId)

@router.post("/appointments/{appointmentId}/end-video-call")
async def user_end_video_call(appointmentId: int, req: Request, user_id: int = Depends(auth_user)):
    body = {}
    if req.headers.get('content-type', '').startswith('application/json'):
        try:
            body = await req.json()
        except Exception:
            body = {}
    return await consultation_controller.end_video_call_for_user(user_id, appointmentId, body)


@router.post("/fcm-token")
async def register_fcm_token(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    return await user_controller.register_fcm_token(user_id, body)


@router.delete("/fcm-token")
async def remove_fcm_token(req: Request, user_id: int = Depends(auth_user)):
    body = await req.json()
    return await user_controller.remove_fcm_token(user_id, body)


@router.post("/telegram/link-code")
async def telegram_link_code(user_id: int = Depends(auth_user)):
    from app.controllers import telegram_link_controller

    return await telegram_link_controller.create_app_link_code(user_id)


@router.get("/telegram/status")
async def telegram_link_status(user_id: int = Depends(auth_user)):
    from app.controllers import telegram_link_controller

    return await telegram_link_controller.get_telegram_link_status(user_id)
