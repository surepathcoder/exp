from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List
from app.models import RoleEnum, CurrencyEnum

class UserBase(BaseModel):
    name: str
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int
    role: RoleEnum
    created_at: datetime

    class Config:
        from_attributes = True

class ExpenseBase(BaseModel):
    amount: float
    currency: CurrencyEnum
    category: str
    date: datetime
    note: Optional[str] = None
    is_self_receipt: bool = False
    payment_method: Optional[str] = None
    location: Optional[str] = None
    photo_url: Optional[str] = None

class ExpenseCreate(ExpenseBase):
    pass

class ExpenseResponse(ExpenseBase):
    id: int
    user_id: int
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class LoginRequest(BaseModel):
    email: EmailStr
