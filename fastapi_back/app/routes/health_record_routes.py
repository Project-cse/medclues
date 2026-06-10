from fastapi import APIRouter, Request, Depends, File, UploadFile, Form
from typing import List, Optional
from app.controllers import health_record_controller
from app.middleware.auth import auth_user, auth_doctor

router = APIRouter(prefix="/api/health-records", tags=["Health Record"])


def _client_ip(request: Request) -> str | None:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    if request.client:
        return request.client.host
    return None

@router.post("/create")
async def create_health_record(
    record_type: str = Form(...),
    title: str = Form(None),
    description: str = Form(None),
    doctor_name: str = Form(None),
    doc_id: Optional[int] = Form(None),
    appointment_id: Optional[int] = Form(None),
    date_str: str = Form(None),
    tags: str = Form(None),
    is_important: bool = Form(False),
    files: List[UploadFile] = File(...),
    user_id: int = Depends(auth_user)
):
    return await health_record_controller.create_health_record(
        user_id, record_type, title, description, doctor_name, doc_id, 
        appointment_id, date_str, tags, is_important, files
    )

@router.get("/list")
async def get_health_records(req: Request, user_id: int = Depends(auth_user)):
    params = dict(req.query_params)
    return await health_record_controller.get_health_records(user_id, params)

@router.delete("/delete/{record_id}")
async def delete_health_record(record_id: int, user_id: int = Depends(auth_user)):
    return await health_record_controller.delete_health_record(user_id, record_id)

@router.get("/patient-records/{appointment_id}")
async def get_patient_records_for_doctor(
    req: Request,
    appointment_id: int,
    doc_id: int = Depends(auth_doctor),
):
    return await health_record_controller.get_patient_records_for_doctor(
        doc_id,
        appointment_id,
        ip_address=_client_ip(req),
        user_agent=req.headers.get("User-Agent"),
    )
