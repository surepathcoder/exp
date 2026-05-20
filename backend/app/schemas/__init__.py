"""Schemas package — re-exports all schemas for backward compatibility."""
from app.schemas.core import (
    UserBase, UserCreate, UserResponse,
    ExpenseBase, ExpenseCreate, ExpenseResponse,
    Token, LoginRequest,
    IncomeBase, IncomeCreate, IncomeResponse,
    TransferBase, TransferCreate, TransferResponse,
    NotificationBase, NotificationCreate, NotificationResponse,
    UserNotificationResponse, UnreadCountResponse,
)
from app.schemas.settings_schemas import SystemSettingsResponse, SystemSettingsUpdate
from app.schemas.category_schemas import (
    CategoryResponse, CategoryCreate, CategoryUpdate, CategoryReorder,
)
from app.schemas.user_management_schemas import (
    CreateUserRequest, ResetPasswordRequest, ChangePasswordRequest,
    SystemStatsResponse, AuditLogResponse,
)

__all__ = [
    "UserBase", "UserCreate", "UserResponse",
    "ExpenseBase", "ExpenseCreate", "ExpenseResponse",
    "Token", "LoginRequest",
    "IncomeBase", "IncomeCreate", "IncomeResponse",
    "TransferBase", "TransferCreate", "TransferResponse",
    "NotificationBase", "NotificationCreate", "NotificationResponse",
    "UserNotificationResponse", "UnreadCountResponse",
    "SystemSettingsResponse", "SystemSettingsUpdate",
    "CategoryResponse", "CategoryCreate", "CategoryUpdate", "CategoryReorder",
    "CreateUserRequest", "ResetPasswordRequest", "ChangePasswordRequest",
    "SystemStatsResponse", "AuditLogResponse",
]
