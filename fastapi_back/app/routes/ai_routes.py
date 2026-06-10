from fastapi import APIRouter, Request, Depends
from fastapi.responses import StreamingResponse
import httpx
import json
from app.controllers import ai_controller
from app.middleware.auth import auth_user
from app.config.config import settings
from app.utils.app_logger import get_logger

router = APIRouter(prefix="/api/ai", tags=["AI Assistant"])
log = get_logger(__name__)

_cached_token = None

async def get_medichain_bot_token():
    global _cached_token
    if not settings.MEDICHAIN_BOT_BASE_URL or not settings.MEDICHAIN_BOT_API_KEY:
        log.warning("MediChain Bot not configured")
        return None
    try:
        async with httpx.AsyncClient() as client:
            res = await client.post(
                f"{settings.MEDICHAIN_BOT_BASE_URL}/api/v1/external/auth/token",
                json={
                    "api_key": settings.MEDICHAIN_BOT_API_KEY,
                    "password": settings.MEDICHAIN_BOT_PASSWORD,
                },
                headers={"Content-Type": "application/json"},
                timeout=10.0,
            )
            if res.status_code == 200:
                data = res.json()
                _cached_token = data.get("access_token")
                return _cached_token
            log.warning("MediChain Bot auth failed with status %s", res.status_code)
            return None
    except Exception as e:
        log.error("MediChain Bot auth error: %s", type(e).__name__)
        return _cached_token

@router.post("/chat/stream")
async def ai_chat_stream(req: Request):
    body = await req.json()
    message = body.get('message')
    
    token = await get_medichain_bot_token()
    if not token:
        async def error_generator():
            yield f"data: {json.dumps({'content': 'Authentication with the MediChain Bot service failed. Please check the backend .env configuration.'})}\n\n"
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
                    f"{settings.MEDICHAIN_BOT_BASE_URL}/api/v1/external/chat/stream",
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
