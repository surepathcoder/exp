"""Audit log router — paginated read-only access."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models import User
from app.auth import get_current_superadmin
from app.schemas import AuditLogResponse
from app.services import audit_service

router = APIRouter(prefix="/api/settings/audit-logs", tags=["audit"])


@router.get("", response_model=List[AuditLogResponse])
def get_audit_logs(
    limit: int = Query(default=50, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superadmin),
):
    """Get paginated audit logs — SuperAdmin only."""
    return audit_service.get_audit_logs(db, limit, offset)


@router.get("/count")
def get_audit_count(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superadmin),
):
    return {"count": audit_service.get_audit_count(db)}
