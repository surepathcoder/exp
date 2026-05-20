from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas import Token, LoginRequest, UserResponse
from app.auth import authenticate_user, create_access_token, get_current_user
from app.models import User

router = APIRouter(prefix="/api/auth", tags=["auth"])

@router.post("/login", response_model=dict)
def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    user = authenticate_user(db, login_data.email, login_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(data={"sub": user.email})
    return {
        "user": UserResponse.from_orm(user),
        "token": Token(access_token=access_token, token_type="bearer")
    }

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user
