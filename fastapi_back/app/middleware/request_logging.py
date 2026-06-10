import time

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.utils.app_logger import get_logger

log = get_logger("medclues.http")

_SKIP_PATHS = frozenset({"/health", "/ready"})


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.url.path in _SKIP_PATHS:
            return await call_next(request)

        start = time.perf_counter()
        status_code = 500
        try:
            response = await call_next(request)
            status_code = response.status_code
            return response
        finally:
            elapsed_ms = (time.perf_counter() - start) * 1000
            log.info(
                "%s %s %s %.1fms",
                request.method,
                request.url.path,
                status_code,
                elapsed_ms,
            )
