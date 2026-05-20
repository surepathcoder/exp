from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.models import CurrencyEnum


class SystemSettingsResponse(BaseModel):
    """Read response for system settings."""
    id: int
    app_name: str
    default_currency: CurrencyEnum
    use_live_rates: bool
    manual_rates: Optional[dict] = None
    session_timeout_minutes: int
    notification_defaults: Optional[dict] = None
    version: int
    updated_at: Optional[datetime] = None
    updated_by: Optional[int] = None

    class Config:
        from_attributes = True


class SystemSettingsUpdate(BaseModel):
    """Update payload — all fields optional, version required for optimistic lock."""
    app_name: Optional[str] = None
    default_currency: Optional[CurrencyEnum] = None
    use_live_rates: Optional[bool] = None
    manual_rates: Optional[dict] = None
    session_timeout_minutes: Optional[int] = None
    notification_defaults: Optional[dict] = None
    version: int  # Required — optimistic locking
