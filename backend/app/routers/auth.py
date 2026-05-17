from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas import Token, LoginRequest, UserResponse
from app.auth import authenticate_user, create_access_token, get_current_user
from app.models import User

router = APIRouter(prefix="/api/auth", tags=["auth"])

@router.post("/login", response_model=dict)
def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    # Simple login handling only email as requested, though usually we need a password
    # For demo purposes and following the requirement "email only, return user + token":
    # Actually, the user requirement said: POST /api/auth/login (email only... Wait, prompt says: "email only, return user + token", but also says "Password hashing with bcrypt".
    # I will support both just in case, but prioritize the prompt's explicit "(email only)" if password is not provided, 
    # but wait, the prompt schema for LoginRequest had just email?
    # Ah, let's check what I defined in schemas.py: LoginRequest has only email.
    # Okay, I will authenticate by email only as requested, though it's insecure.
    # Actually, wait. The prompt said "Password hashing with bcrypt" in auth.py requirements, but then "POST /api/auth/login (email only, return user + token)". This is a contradiction, but I will follow the explicit endpoint instruction. I'll just find the user by email.
    
    user = db.query(User).filter(User.email == login_data.email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email",
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
