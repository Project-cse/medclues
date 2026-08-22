from datetime import datetime, timedelta, date
from typing import Dict, Any

def is_investigation_pending_review(inv: Dict[str, Any], threshold_minutes: int = 30) -> bool:
    """Returns True if the investigation has a report available but hasn't been reviewed

    and has exceeded the threshold minutes since the report was made available.
    """
    status = inv.get("status")
    if status != "REPORT_AVAILABLE":
        return False
        
    updated_at = inv.get("updated_at")
    if not updated_at:
        return False

    # Standardize datetime
    if isinstance(updated_at, str):
        try:
            # Parse ISO timestamp
            updated_at = datetime.fromisoformat(updated_at.replace("Z", "+00:00"))
        except ValueError:
            return False
            
    now = datetime.now(updated_at.tzinfo)
    return now - updated_at > timedelta(minutes=threshold_minutes)
