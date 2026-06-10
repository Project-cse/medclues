import asyncio
import uvicorn
from fastapi import FastAPI, Request, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.config.config import settings, validate_settings, cors_allowed_origins
from app.utils.app_logger import get_logger

log = get_logger("medclues.api")
validate_settings()
from app.config.db import db
from contextlib import asynccontextmanager
log.info("Importing routes...")
from app.routes import (
    admin_routes, doctor_routes, user_routes, appointment_routes,
    blood_bank_routes, lab_routes, hospital_routes,
    health_record_routes, emergency_routes, ai_routes,
    job_application_routes, otp_routes, specialty_routes,
    location_routes, dean_routes, super_appointment_routes,
    payments_routes, charts_routes, auth_routes, health_routes,
)
from app.middleware.request_logging import RequestLoggingMiddleware
log.info("Routes imported.")
import cloudinary
import cloudinary.uploader
import os
from fastapi.staticfiles import StaticFiles

# Cloudinary Configuration
cloudinary.config(
    cloud_name=settings.CLOUDINARY_NAME,
    api_key=settings.CLOUDINARY_API_KEY,
    api_secret=settings.CLOUDINARY_API_SECRET,
    secure=True
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    log.info("Starting FastAPI application...")
    log.info("Connecting to DB in lifespan...")
    success = await db.connect()
    if not success:
        log.warning("PostgreSQL not connected — login/API will retry on first request.")
    else:
        log.info("PostgreSQL connected.")
        # Auto-create DEAN table if it doesn't exist
        try:
            from app.models import dean_model
            log.info("Preparing DEAN table...")
            await dean_model.create_deans_table()
            log.info("DEAN table ready")
        except Exception as _e:
            log.warning("Could not create deans table: %s", _e)
        try:
            from app.models import appointment_model
            await appointment_model.ensure_booking_id_column()
            log.info("Appointments booking_id column ready")
        except Exception as _e:
            log.warning("Could not ensure booking_id column: %s", _e)
        try:
            from app.models import refresh_token_model
            await refresh_token_model.ensure_refresh_tokens_table()
            log.info("Refresh tokens table ready")
        except Exception as _e:
            log.warning("Could not ensure refresh_tokens table: %s", _e)
        try:
            from app.models import payment_transaction_model
            await payment_transaction_model.ensure_payment_transactions_table()
            log.info("Payment transactions table ready")
        except Exception as _e:
            log.warning("Could not ensure payment_transactions table: %s", _e)
        try:
            from app.models import emergency_event_model
            await emergency_event_model.ensure_emergency_events_table()
            log.info("Emergency events table ready")
        except Exception as _e:
            log.warning("Could not ensure emergency_events table: %s", _e)
        try:
            from app.models import audit_log_model
            await audit_log_model.ensure_audit_logs_table()
            log.info("Audit logs table ready")
        except Exception as _e:
            log.warning("Could not ensure audit_logs table: %s", _e)
        try:
            from app.db.migration_runner import run_pending_migrations
            applied = await run_pending_migrations()
            if applied:
                log.info("SQL migrations applied: %s", ", ".join(applied))
            else:
                log.info("SQL migrations up to date")
        except Exception as _e:
            log.warning("Could not run SQL migrations: %s", _e)
        try:
            from app.models import fcm_token_model
            await fcm_token_model.ensure_fcm_tokens_table()
            log.info("FCM tokens table ready")
        except Exception as _e:
            log.warning("Could not ensure fcm_tokens table: %s", _e)
        try:
            from app.services import fcm_service
            fcm_service._ensure_firebase()
        except Exception as _e:
            log.warning("Firebase Admin init skipped: %s", _e)
        try:
            from app.models import doctor_slot_model
            from app.services import doctor_slot_service
            await doctor_slot_model.ensure_doctor_slots_schema()
            await doctor_slot_model.ensure_appointment_slot_id_column()

            async def _warm_doctor_slots():
                try:
                    await doctor_slot_service.ensure_all_doctors_scheduled()
                    log.info("Doctor slots schedule ready")
                except Exception as warm_err:
                    log.warning("Doctor slots warm-up failed: %s", warm_err)

            asyncio.create_task(_warm_doctor_slots())
            log.info("Doctor slots schema ready (schedule warming in background)")
        except Exception as _e:
            log.warning("Could not ensure doctor slots: %s", _e)
    try:
        from app.services.telegram_polling import start_telegram_bot
        asyncio.create_task(start_telegram_bot())
    except Exception as tg_err:
        log.warning("Telegram bot could not start: %s", tg_err)
    yield
    # Shutdown logic
    log.info("Stopping FastAPI application...")
    try:
        from app.services.telegram_polling import stop_telegram_bot
        await stop_telegram_bot()
    except Exception:
        pass
    await db.disconnect()

# Initialize FastAPI App
app = FastAPI(
    title="MediChain API (Python)",
    description="Drop-in replacement for Node.js backend",
    version="1.0.0",
    lifespan=lifespan
)

# CORS — DEBUG: any localhost port; production: explicit allowlist only (no wildcard).
_cors_common = {
    "allow_credentials": True,
    "allow_methods": ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    "allow_headers": [
        "Authorization",
        "Content-Type",
        "token",
        "Token",
        "atoken",
        "dtoken",
        "deantoken",
        "x-auth-storage",
        "x-client-platform",
    ],
}
if settings.DEBUG:
    _cors_kwargs = {
        **_cors_common,
        "allow_origin_regex": r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    }
else:
    _cors_kwargs = {
        **_cors_common,
        "allow_origins": cors_allowed_origins(),
    }

app.add_middleware(CORSMiddleware, **_cors_kwargs)
app.add_middleware(RequestLoggingMiddleware)

# Register Routers
app.include_router(health_routes.router)
app.include_router(admin_routes.router)
app.include_router(doctor_routes.router)
app.include_router(user_routes.router)
app.include_router(appointment_routes.router)
app.include_router(blood_bank_routes.router)
app.include_router(lab_routes.router)
app.include_router(hospital_routes.router)
app.include_router(health_record_routes.router)
app.include_router(emergency_routes.router)
app.include_router(ai_routes.router)
app.include_router(job_application_routes.router)
app.include_router(otp_routes.router)
app.include_router(specialty_routes.router)
app.include_router(location_routes.router)
app.include_router(dean_routes.router)
app.include_router(super_appointment_routes.router)
app.include_router(payments_routes.router)
app.include_router(charts_routes.router)
app.include_router(auth_routes.router)

# --- Real-time Socket.IO ---
from app.services.socket_service import sio_app
# Mounting at /socket.io to allow handling while keeping other routes accessible
app.mount("/socket.io", sio_app)

# --- Real-time Payment Updates (WebSocket) ---
from app.services.websocket_service import manager

@app.websocket("/payment-updates")
async def websocket_endpoint(websocket: WebSocket):
    appointment_id = websocket.query_params.get("appointmentId")
    if not appointment_id:
        await websocket.close(code=1008)
        return

    await manager.connect(websocket, appointment_id)
    try:
        while True:
            # Keep connection alive
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, appointment_id)
    except Exception as e:
        print(f"WebSocket Error: {e}")
        manager.disconnect(websocket, appointment_id)

from fastapi.exceptions import RequestValidationError

from fastapi.encoders import jsonable_encoder

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    log.warning("Validation error on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=422,
        content=jsonable_encoder({"success": False, "message": "Validation Error", "detail": exc.errors()})
    )

@app.get("/api/config/integrations")
async def integrations_config():
    from app.services import agora_service
    return {
        "success": True,
        "agora": agora_service.agora_configured(),
        "agoraAppId": settings.AGORA_APP_ID if agora_service.agora_configured() else None,
        "razorpay": bool(settings.RAZORPAY_KEY_ID),
    }

# Root Endpoint
@app.get("/")
async def root():
    return {"message": "API Working", "version": "1.0.0", "status": "Ready"}

# Global Error Handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    log.error("Unhandled error on %s %s: %s", request.method, request.url.path, type(exc).__name__)
    return JSONResponse(
        status_code=500,
        content={"success": False, "message": "Internal server error."}
    )

# Create uploads directory if it doesn't exist
if not os.path.exists("uploads"):
    os.makedirs("uploads")

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=int(settings.PORT), reload=True)
