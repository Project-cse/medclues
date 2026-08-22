from fastapi import APIRouter, Request, Depends, HTTPException
from fastapi.responses import StreamingResponse
import httpx
import json
from app.controllers import ai_controller
from app.middleware.auth import auth_user, auth_assistant
from app.config.config import settings
from app.utils.app_logger import get_logger
from app.routes.order_routing_routes import auth_staff_role

router = APIRouter(prefix="/api/ai", tags=["AI Assistant"])
log = get_logger(__name__)

_cached_token = None

async def get_medclues_bot_token():
    global _cached_token
    if not settings.MEDCLUES_BOT_BASE_URL or not settings.MEDCLUES_BOT_API_KEY:
        log.warning("MedClues Bot not configured")
        return None
    try:
        async with httpx.AsyncClient() as client:
            res = await client.post(
                f"{settings.MEDCLUES_BOT_BASE_URL}/api/v1/external/auth/token",
                json={
                    "api_key": settings.MEDCLUES_BOT_API_KEY,
                    "password": settings.MEDCLUES_BOT_PASSWORD,
                },
                headers={"Content-Type": "application/json"},
                timeout=10.0,
            )
            if res.status_code == 200:
                data = res.json()
                _cached_token = data.get("access_token")
                return _cached_token
            log.warning("MedClues Bot auth failed with status %s", res.status_code)
            return None
    except Exception as e:
        log.error("MedClues Bot auth error: %s", type(e).__name__)
        return _cached_token


# Legacy alias
get_medichain_bot_token = get_medclues_bot_token

@router.post("/chat/stream")
async def ai_chat_stream(req: Request):
    body = await req.json()
    message = body.get('message')
    
    token = await get_medclues_bot_token()
    if not token:
        async def error_generator():
            yield f"data: {json.dumps({'content': 'Authentication with the MedClues Bot service failed. Please check the backend .env configuration.'})}\n\n"
        return StreamingResponse(error_generator(), media_type="text/event-stream")
    
    async def event_generator():
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        # Never send DATABASE_URL or internal credentials to external AI services.
        payload = {
            "database_name": "MEDCLUES",
            "message": message
        }
        
        async with httpx.AsyncClient() as client:
            try:
                async with client.stream(
                    "POST",
                    f"{settings.MEDCLUES_BOT_BASE_URL}/api/v1/external/chat/stream",
                    headers=headers,
                    json=payload,
                    timeout=120.0
                ) as response:
                    async for chunk in response.aiter_text():
                        yield chunk
            except Exception as e:
                log.error("AI stream error: %s", type(e).__name__)
                yield f"data: {json.dumps({'content': 'Connection lost. Please try again.'})}\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")

@router.post("/chat")
async def ai_chat(req: Request):
    body = await req.json()
    message = body.get('message')
    conversation_history = body.get('conversationHistory')
    user_id = None
    try:
        pass
    except: pass
    
    return await ai_controller.ai_chat(message, conversation_history, user_id)

@router.post("/chat-medical")
async def ai_chat_medical(req: Request):
    return await ai_chat(req)

@router.get("/doctor-slots/{doc_id}")
async def get_doctor_slots(doc_id: int):
    return await ai_controller.get_doctor_slots(doc_id)

@router.get("/appointments-context")
async def get_appointments_context(user_id: int = Depends(auth_user)):
    return await ai_controller.get_user_appointments_context(user_id)


@router.get("/assistant/status")
async def assistant_status():
    from app.services import ai_assistant_service as asist
    from app.services.ai import provider as ai_provider
    from app.config.config import settings as cfg

    return {
        "success": True,
        "enabled": asist.is_enabled(),
        "disclaimer": asist.DISCLAIMER,
        "rag": True,
        "layers": ["llm", "knowledge_rag", "tools"],
        "features": {
            "llm": ai_provider.is_enabled(),
            "llmProvider": ai_provider.provider_name(),
            "llmModel": ai_provider.model_name() if ai_provider.is_enabled() else None,
            "confirmWrites": True,
            "redisMemory": bool(getattr(cfg, "REDIS_URL", "")),
            "communityFirst": True,
            "pharmacy": True,
            "laboratory": True,
            "complaints": True,
            "cancelReschedule": True,
            "payments": True,
            "navigation": True,
            "feedback": True,
            "ragFts": True,
        },
    }


@router.get("/assistant/tools")
async def assistant_tools(actor: dict = Depends(auth_assistant)):
    from app.services import ai_assistant_service as asist

    if not asist.is_enabled():
        return {"success": False, "message": "AI Assistant disabled", "tools": []}
    return {
        "success": True,
        "role": actor.get("role"),
        "tools": asist.list_tools_for_role(str(actor.get("role") or "patient")),
        "disclaimer": asist.DISCLAIMER,
    }


@router.post("/assistant/chat")
async def assistant_chat(req: Request, actor: dict = Depends(auth_assistant)):
    """Enterprise AI gateway: intent → RAG → tools. Never diagnoses. No direct DB from LLM."""
    from app.services import ai_assistant_service as asist

    body = await req.json()
    lat = body.get("lat") if body.get("lat") is not None else body.get("latitude")
    lng = body.get("lng") if body.get("lng") is not None else body.get("longitude")
    try:
        lat_f = float(lat) if lat is not None else None
    except (TypeError, ValueError):
        lat_f = None
    try:
        lng_f = float(lng) if lng is not None else None
    except (TypeError, ValueError):
        lng_f = None
    return await asist.assistant_chat(
        message=str(body.get("message") or ""),
        role=str(actor.get("role") or "patient"),
        user_id=int(actor["id"]) if actor.get("id") is not None else None,
        hospital_id=actor.get("hospital_id"),
        session_id=str(body.get("sessionId") or body.get("session_id") or "default")[:64],
        tool=body.get("tool"),
        tool_args=body.get("toolArgs") or body.get("args") or {},
        confirm=bool(body.get("confirm")),
        lat=lat_f,
        lng=lng_f,
    )


@router.post("/assistant/confirm")
async def assistant_confirm(req: Request, actor: dict = Depends(auth_assistant)):
    """Confirm a mutating tool (book/cancel/ticket/lab/reschedule)."""
    from app.services import ai_assistant_service as asist

    body = await req.json()
    tool = body.get("tool")
    if not tool:
        return {"success": False, "message": "tool required"}
    return await asist.assistant_chat(
        message=str(body.get("message") or f"confirm {tool}"),
        role=str(actor.get("role") or "patient"),
        user_id=int(actor["id"]) if actor.get("id") is not None else None,
        hospital_id=actor.get("hospital_id"),
        session_id=str(body.get("sessionId") or "default")[:64],
        tool=str(tool),
        tool_args=body.get("toolArgs") or body.get("args") or {},
        confirm=True,
    )


@router.post("/assistant/feedback")
async def assistant_feedback(req: Request, actor: dict = Depends(auth_assistant)):
    """Thumbs up/down for continuous improvement (no clinical content required)."""
    from app.services.ai import metrics as ai_metrics

    body = await req.json()
    return await ai_metrics.record_feedback(
        user_id=int(actor["id"]) if actor.get("id") is not None else None,
        role=str(actor.get("role") or "patient"),
        session_id=str(body.get("sessionId") or "default")[:64],
        intent=body.get("intent"),
        tool=body.get("tool"),
        rating=int(body.get("rating") or 0),
        comment=str(body.get("comment") or "")[:1000] or None,
        query=str(body.get("query") or "")[:500] or None,
        grounded=body.get("grounded"),
    )


@router.get("/patient-journeys")
async def list_patient_journeys(actor: dict = Depends(auth_staff_role)):
    from app.services import patient_journey_service as pjs

    journeys = await pjs.list_staff_journeys(actor)
    return {"success": True, "journeys": journeys}


@router.get("/patient-journey/{patient_id}")
async def get_patient_journey(patient_id: int, actor: dict = Depends(auth_staff_role)):
    from app.services import patient_journey_service as pjs

    result = await pjs.build_patient_journey(int(patient_id), staff_view=True)
    if not result.get("success"):
        raise HTTPException(status_code=404, detail=result.get("message") or "Not found")
    return result


@router.post("/patient-journey/{patient_id}/refresh")
async def refresh_patient_journey(patient_id: int, actor: dict = Depends(auth_staff_role)):
    from app.services.order_monitoring_service import run_order_monitoring_cycle
    from app.services import patient_journey_service as pjs

    await run_order_monitoring_cycle()
    result = await pjs.build_patient_journey(int(patient_id), staff_view=True)
    if not result.get("success"):
        raise HTTPException(status_code=404, detail=result.get("message") or "Not found")
    return result


@router.post("/findings/{finding_id}/review")
async def review_finding(finding_id: int, req: Request, actor: dict = Depends(auth_staff_role)):
    from app.services import patient_journey_service as pjs

    body = await req.json()
    result = await pjs.apply_human_review(
        finding_id=int(finding_id),
        actor=actor,
        decision=str(body.get("decision") or body.get("review_decision") or ""),
        note=body.get("note") or body.get("resolution_note"),
        modifications=body.get("modifications") or {},
    )
    if not result.get("success"):
        raise HTTPException(status_code=400, detail=result.get("message") or "Review failed")
    return result


@router.get("/my-care-journey")
async def my_care_journey(user_id: int = Depends(auth_user)):
    from app.services import patient_journey_service as pjs

    try:
        await pjs.verify_and_close_stale_findings(patient_id=int(user_id))
    except Exception:
        pass
    return await pjs.build_patient_journey(int(user_id), staff_view=False)
