"""Settings router — system configuration endpoints."""
from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.auth import get_current_superadmin, get_current_admin
from app.schemas import SystemSettingsResponse, SystemSettingsUpdate
from app.services import settings_service

router = APIRouter(prefix="/api/settings", tags=["settings"])


@router.get("", response_model=SystemSettingsResponse)
def get_settings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin),
):
    """Get system settings. Admins get read-only, SuperAdmins get full access."""
    return settings_service.get_settings(db)


@router.put("", response_model=SystemSettingsResponse)
def update_settings(
    update: SystemSettingsUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superadmin),
):
    """Update system settings. Requires SuperAdmin + optimistic lock version."""
    ip = request.client.host if request.client else None
    return settings_service.update_settings(db, update, current_user, ip)
