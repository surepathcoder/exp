"""Audit logging service — append-only change tracking."""
import json
from sqlalchemy.orm import Session
from app.models import AuditLog, User


def log_change(
    db: Session,
    user: User,
    action: str,
    entity_type: str,
    entity_id: str = None,
    before: dict = None,
    after: dict = None,
    ip_address: str = None,
):
    """Create an immutable audit log entry."""
    entry = AuditLog(
        user_id=user.id,
        user_email=user.email,
        action=action,
        entity_type=entity_type,
        entity_id=str(entity_id) if entity_id else None,
        before_value=json.dumps(before) if before else None,
        after_value=json.dumps(after) if after else None,
        ip_address=ip_address,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


def get_audit_logs(db: Session, limit: int = 50, offset: int = 0):
    """Fetch paginated audit logs, newest first."""
    return (
        db.query(AuditLog)
        .order_by(AuditLog.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )


def get_audit_count(db: Session) -> int:
    return db.query(AuditLog).count()
