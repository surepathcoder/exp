from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import random
from datetime import datetime, timedelta

from app.database import get_db
from app.schemas import Token, LoginRequest, UserResponse, ForgotPasswordRequest, PublicResetPasswordRequest, UserCreate
from app.auth import authenticate_user, create_access_token, get_current_user, get_password_hash
from app.models import User, RoleEnum

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
    
    if not user.is_approved:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your account is pending admin approval.",
        )
    
    access_token = create_access_token(data={"sub": user.email})
    return {
        "user": UserResponse.from_orm(user),
        "token": Token(access_token=access_token, token_type="bearer")
    }

@router.post("/register", response_model=UserResponse)
async def register(register_data: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == register_data.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    user = User(
        name=register_data.name,
        email=register_data.email,
        password_hash=get_password_hash(register_data.password),
        role=RoleEnum.user,
        is_approved=False,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    try:
        admins = db.query(User).filter(User.role.in_([RoleEnum.admin, RoleEnum.superadmin])).all()
        from app.utils.notification_helper import create_notification
        for admin in admins:
            await create_notification(
                db=db,
                title="New User Registered",
                message=f"{user.name} ({user.email}) registered and is pending approval.",
                type="info",
                priority="high",
                target_user_id=admin.id
            )
    except Exception as e:
        print(f"Error sending registration notification to admins: {e}")
        
    return user

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user

@router.post("/forgot-password")
def forgot_password(data: ForgotPasswordRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No account found with this email address."
        )
        
    # Generate 6-digit verification code
    code = str(random.randint(100000, 999999))
    user.reset_token = code
    user.reset_token_expires = datetime.utcnow() + timedelta(minutes=15)
    db.commit()
    
    # Log to terminal console for local development verification
    print("\n" + "=" * 50)
    print(f"PASSWORD RESET REQUEST FOR: {user.email}")
    print(f"VERIFICATION CODE: {code}")
    print("=" * 50 + "\n")
    
    res = {"status": "ok", "message": "Password reset code has been sent."}
    
    from app.config import settings as app_settings
    if app_settings.ENV != "production":
        res["debug_code"] = code
        
    return res

@router.post("/reset-password")
def reset_password(data: PublicResetPasswordRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        
    if not user.reset_token or user.reset_token != data.token:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid reset code")
        
    if not user.reset_token_expires or user.reset_token_expires < datetime.utcnow():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Reset code has expired")
        
    if len(data.new_password) < 6:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Password must be at least 6 characters")
        
    user.password_hash = get_password_hash(data.new_password)
    user.reset_token = None
    user.reset_token_expires = None
    db.commit()
    
    return {"status": "ok", "message": "Password has been successfully updated."}

