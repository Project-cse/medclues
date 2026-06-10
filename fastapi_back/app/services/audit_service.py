from typing import Any, Optional

from app.models import audit_log_model
from app.utils.app_logger import get_logger

log = get_logger(__name__)


async def log_access(
    *,
    action: str,
    resource: str,
    resource_id: Optional[str | int] = None,
    actor_id: Optional[int] = None,
    actor_role: Optional[str] = None,
    ip_address: Optional[str] = None,
    user_agent: Optional[str] = None,
    metadata: Optional[dict[str, Any]] = None,
) -> None:
    try:
        await audit_log_model.insert_log(
            action=action,
            resource=resource,
            resource_id=str(resource_id) if resource_id is not None else None,
            actor_id=actor_id,
            actor_role=actor_role,
            ip_address=ip_address,
            user_agent=user_agent,
            metadata=metadata,
        )
    except Exception as exc:
        log.warning("Audit log write failed: %s", exc)
