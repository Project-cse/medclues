from fastapi import Request, HTTPException, Security, Depends
import fastapi.security
from jose import jwt, JWTError
from app.config.config import settings
from app.services.token_service import verify_access_payload
from app.utils.app_logger import get_logger
from datetime import datetime

security = fastapi.security.HTTPBearer(auto_error=False)
logger = get_logger(__name__)

async def auth_user(request: Request, token: fastapi.security.HTTPAuthorizationCredentials = Depends(security)):
    # Try getting token from Bearer header OR from 'token' header
    token_str = token.credentials if token else None
    
    if not token_str:
        token_str = request.headers.get("token") or request.headers.get("Token")
        
    # Extra check: Authorization header might be sent without 'Bearer ' prefix
    if not token_str:
        auth_header = request.headers.get("Authorization")
        if auth_header and not auth_header.startswith("Bearer "):
            token_str = auth_header
        
    if not token_str:
        logger.warning("Auth failed: no token in request headers")
        raise HTTPException(status_code=401, detail="No token provided")
        
    try:
        secret = settings.JWT_SECRET.strip('"').strip("'")
        payload = jwt.decode(token_str, secret, algorithms=["HS256"])
        verify_access_payload(payload)

        user_id = payload.get("id")
        if user_id is None:
            # Try 'userId' just in case
            user_id = payload.get("userId")
            
        if user_id is None:
            logger.warning("Auth failed: token missing user id claim")
            raise HTTPException(status_code=401, detail="Invalid token")
            
        return user_id
    except JWTError as e:
        logger.warning("Auth JWT error: %s", str(e))
        raise HTTPException(status_code=401, detail="Not authorized, login again")

async def auth_admin(request: Request, token: fastapi.security.HTTPAuthorizationCredentials = Depends(security)):
    # Try getting token from Bearer header OR from 'atoken' / 'aToken' / 'token' header
    token_str = token.credentials if token else None
    
    if not token_str:
        all_headers = dict(request.headers)
        token_str = all_headers.get("atoken") or all_headers.get("token") or all_headers.get("Token")
        if not token_str:
            for k, v in all_headers.items():
                if k.lower() in ["atoken", "token"]:
                    token_str = v
                    break

    if not token_str:
        auth_header = request.headers.get("Authorization")
        if auth_header and not auth_header.startswith("Bearer "):
            token_str = auth_header

    if not token_str:
        logger.warning("Admin auth failed: no token in headers")
        raise HTTPException(status_code=401, detail="No admin token provided")
        
    try:
        secret = settings.JWT_SECRET.strip('"').strip("'")
        payload = jwt.decode(token_str, secret, algorithms=["HS256"])
        verify_access_payload(payload)
        email = payload.get("email")

        expected_admin = getattr(settings, "ADMIN_EMAIL", None)
        if not expected_admin:
            logger.error("ADMIN_EMAIL not configured")
            raise HTTPException(status_code=500, detail="Server configuration error")

        if not email or str(email).strip().lower() != str(expected_admin).strip().lower():
            logger.warning("Admin auth failed: unauthorized email claim")
            raise HTTPException(status_code=401, detail="Not authorized as admin")
        return email
    except JWTError as e:
        logger.warning("Admin auth JWT error: %s", str(e))
        raise HTTPException(status_code=401, detail="Not authorized, login again")

async def auth_doctor(request: Request, token: fastapi.security.HTTPAuthorizationCredentials = Depends(security)):
    # Try getting token from Bearer header OR from 'dtoken' / 'dToken' / 'token' header
    token_str = token.credentials if token else None
    if not token_str:
        token_str = request.headers.get("dtoken") or request.headers.get("dToken") or \
                    request.headers.get("token") or request.headers.get("Token")
        
    if not token_str:
        auth_header = request.headers.get("Authorization")
        if auth_header and not auth_header.startswith("Bearer "):
            token_str = auth_header

    if not token_str:
        raise HTTPException(status_code=401, detail="No doctor token provided")
        
    try:
        secret = settings.JWT_SECRET.strip('"').strip("'")
        payload = jwt.decode(token_str, secret, algorithms=["HS256"])
        verify_access_payload(payload)
        doc_id = payload.get("id")
        if doc_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return doc_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Not authorized, login again")

async def auth_dean(request: Request, token: fastapi.security.HTTPAuthorizationCredentials = Depends(security)):
    """Extract and validate a DEAN JWT. Returns dict with id & hospital_id."""
    token_str = token.credentials if token else None
    if not token_str:
        for header_key in ["deantoken", "dean-token", "token"]:
            token_str = request.headers.get(header_key)
            if token_str:
                break
    if not token_str:
        auth_header = request.headers.get("Authorization")
        if auth_header and not auth_header.startswith("Bearer "):
            token_str = auth_header
    if not token_str:
        raise HTTPException(status_code=401, detail="No DEAN token provided")
    try:
        secret = settings.JWT_SECRET.strip('"').strip("'")
        payload = jwt.decode(token_str, secret, algorithms=["HS256"])
        verify_access_payload(payload)
        if payload.get("role") != "dean":
            raise HTTPException(status_code=403, detail="Access denied: DEAN role required")
        dean_id = payload.get("id")
        hospital_id = payload.get("hospital_id")
        if dean_id is None or hospital_id is None:
            raise HTTPException(status_code=401, detail="Invalid DEAN token")
        return {"id": dean_id, "hospital_id": hospital_id}
    except JWTError:
        raise HTTPException(status_code=401, detail="Not authorized, login again")
