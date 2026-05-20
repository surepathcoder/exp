"""User management router — create users, reset/change passwords."""
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.auth import get_current_user, get_current_superadmin, get_password_hash, verify_password
from app.schemas import (
    CreateUserRequest, ResetPasswordRequest, ChangePasswordRequest, UserResponse,
)
from app.services import audit_service

router = APIRouter(prefix="/api/settings", tags=["user-management"])


@router.post("/users", response_model=UserResponse)
def create_user(
    data: CreateUserRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superadmin),
):
    """Create a new user account — SuperAdmin only."""
    existing = db.query(User).filter(User.email == data.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        name=data.name,
        email=data.email,
        password_hash=get_password_hash(data.password),
        role=data.role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    ip = request.client.host if request.client else None
    audit_service.log_change(
        db, current_user, "create_user", "user", str(user.id),
        None, {"name": user.name, "email": user.email, "role": user.role.value}, ip
    )
    return user


@router.put("/users/{user_id}/reset-password")
def reset_user_password(
    user_id: int,
    data: ResetPasswordRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superadmin),
):
    """Reset another user's password — SuperAdmin only."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.password_hash = get_password_hash(data.new_password)
    db.commit()

    ip = request.client.host if request.client else None
    audit_service.log_change(
        db, current_user, "reset_password", "user", str(user_id),
        None, {"target_user": user.email}, ip
    )
    return {"status": "ok", "message": f"Password reset for {user.email}"}


@router.put("/change-password")
def change_own_password(
    data: ChangePasswordRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Change own password — available to all authenticated users."""
    if not verify_password(data.current_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Current password is incorrect")

    if len(data.new_password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    current_user.password_hash = get_password_hash(data.new_password)
    db.commit()

    ip = request.client.host if request.client else None
    audit_service.log_change(
        db, current_user, "change_password", "user", str(current_user.id),
        None, {"action": "password_changed"}, ip
    )
    return {"status": "ok", "message": "Password updated successfully"}
