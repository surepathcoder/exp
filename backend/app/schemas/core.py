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
    password: str


class IncomeBase(BaseModel):
    amount: float
    currency: CurrencyEnum
    source: str
    date: datetime
    note: Optional[str] = None


class IncomeCreate(IncomeBase):
    pass


class IncomeResponse(IncomeBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True


class TransferBase(BaseModel):
    amount_from: float
    currency_from: CurrencyEnum
    amount_to: float
    currency_to: CurrencyEnum
    date: datetime
    note: Optional[str] = None


class TransferCreate(TransferBase):
    pass


class TransferResponse(TransferBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True


class NotificationBase(BaseModel):
    title: str
    message: str
    type: str = "info"
    priority: str = "normal"
    is_broadcast: bool = False


class NotificationCreate(NotificationBase):
    target_user_id: Optional[int] = None


class NotificationResponse(BaseModel):
    id: int
    title: str
    message: str
    type: str
    priority: str
    is_broadcast: bool
    created_at: datetime
    created_by: Optional[int] = None

    class Config:
        from_attributes = True


class UserNotificationResponse(BaseModel):
    id: int
    is_read: bool
    read_at: Optional[datetime] = None
    notification: NotificationResponse

    class Config:
        from_attributes = True


class UnreadCountResponse(BaseModel):
    count: int
