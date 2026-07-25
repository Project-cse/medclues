from app.models import doctor_model
from app.services import doctor_slot_service


async def get_doctor_slots(doc_id: str, mode: str = "offline"):
    doctor = await doctor_model.get_doctor_by_id(doc_id)
    if not doctor:
        return {"success": False, "message": "Doctor not found"}

    doctor_ref, _ = doctor_slot_service.normalize_doctor_ref(doc_id)
    return await doctor_slot_service.get_public_slots(doctor_ref, mode)
