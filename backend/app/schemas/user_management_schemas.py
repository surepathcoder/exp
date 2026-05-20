from pydantic import BaseModel, EmailStr
from typing import Optional
from app.models import RoleEnum


class CreateUserRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: RoleEnum = RoleEnum.user


class ResetPasswordRequest(BaseModel):
    new_password: str


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


class SystemStatsResponse(BaseModel):
    total_users: int
    total_expenses: int
    total_incomes: int
    total_transfers: int
    total_categories: int
    active_categories: int
    total_expense_amount_usd: float
    total_income_amount_usd: float


class AuditLogResponse(BaseModel):
    id: int
    user_id: int
    user_email: str
    action: str
    entity_type: str
    entity_id: Optional[str] = None
    before_value: Optional[str] = None
    after_value: Optional[str] = None
    ip_address: Optional[str] = None
    created_at: str

    class Config:
        from_attributes = True
