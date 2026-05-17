from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel

from app.database import get_db
from app.schemas import UserResponse
from app.models import User, RoleEnum
from app.auth import get_current_admin, get_current_superadmin, get_current_user

router = APIRouter(prefix="/api/users", tags=["users"])

class RoleUpdateRequest(BaseModel):
    role: RoleEnum

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
