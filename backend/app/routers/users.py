from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel, EmailStr

from app.database import get_db
from app.schemas import UserResponse
from app.models import User, RoleEnum
from app.auth import get_current_admin, get_current_superadmin, get_current_user

router = APIRouter(prefix="/api/users", tags=["users"])

class RoleUpdateRequest(BaseModel):
    role: RoleEnum

class ApprovalUpdateRequest(BaseModel):
    is_approved: bool

@router.get("", response_model=List[UserResponse])
def get_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    return db.query(User).all()

@router.put("/{user_id}/role", response_model=UserResponse)
def update_user_role(
    user_id: int,
    role_update: RoleUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superadmin)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user.role = role_update.role
    db.commit()
    db.refresh(user)
    return user

@router.put("/{user_id}/approval", response_model=UserResponse)
def update_user_approval(
    user_id: int,
    approval_update: ApprovalUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user.is_approved = approval_update.is_approved
    db.commit()
    db.refresh(user)
    
    # Audit log the change
    from app.services import audit_service
    audit_service.log_change(
        db, current_user, "update_user_approval", "user", str(user.id),
        None, {"is_approved": user.is_approved}, None
    )
    
    return user

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superadmin)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    db.delete(user)
    db.commit()

class ProfileUpdateRequest(BaseModel):
    name: str
    email: EmailStr

@router.put("/me", response_model=UserResponse)
def update_profile(
    profile_data: ProfileUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if profile_data.email != current_user.email:
        existing = db.query(User).filter(User.email == profile_data.email).first()
        if existing:
            raise HTTPException(status_code=400, detail="Email already in use")
            
    current_user.name = profile_data.name
    current_user.email = profile_data.email
    db.commit()
    db.refresh(current_user)
    return current_user

