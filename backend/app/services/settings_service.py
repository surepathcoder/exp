"""Settings service — CRUD with caching and optimistic locking."""
from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.models import SystemSettings, User
from app.schemas import SystemSettingsUpdate
from app.services.cache_service import cache
from app.services import audit_service

CACHE_KEY = "system_settings"
CACHE_TTL = 300  # 5 minutes


def get_or_create_settings(db: Session) -> SystemSettings:
    """Get singleton settings row, auto-seed if missing."""
    settings = db.query(SystemSettings).filter(SystemSettings.id == 1).first()
    if not settings:
        settings = SystemSettings(id=1)
        db.add(settings)
        db.commit()
        db.refresh(settings)
    return settings


def get_settings(db: Session) -> SystemSettings:
    """Get settings with caching."""
    cached = cache.get(CACHE_KEY)
    if cached:
        return cached
    settings = get_or_create_settings(db)
    cache.set(CACHE_KEY, settings, CACHE_TTL)
    return settings


def _settings_to_dict(s: SystemSettings) -> dict:
    return {
        "app_name": s.app_name,
        "default_currency": s.default_currency.value if s.default_currency else None,
        "use_live_rates": s.use_live_rates,
        "manual_rates": s.manual_rates,
        "session_timeout_minutes": s.session_timeout_minutes,
        "notification_defaults": s.notification_defaults,
        "version": s.version,
    }


def update_settings(
    db: Session, update: SystemSettingsUpdate, user: User, ip: str = None
) -> SystemSettings:
    """Update settings with optimistic locking and audit trail."""
    settings = get_or_create_settings(db)

    # Optimistic lock check
    if update.version != settings.version:
        raise HTTPException(
            status_code=409,
            detail="Settings were modified by another admin. Please refresh and try again.",
        )

    before = _settings_to_dict(settings)

    # Apply partial updates
    update_data = update.model_dump(exclude_unset=True, exclude={"version"})
    for field, value in update_data.items():
        setattr(settings, field, value)

    settings.version += 1
    settings.updated_by = user.id
    db.commit()
    db.refresh(settings)

    after = _settings_to_dict(settings)

    # Invalidate cache + audit log
    cache.invalidate(CACHE_KEY)
    audit_service.log_change(
        db, user, "update_settings", "system_settings", "1", before, after, ip
    )
    return settings
