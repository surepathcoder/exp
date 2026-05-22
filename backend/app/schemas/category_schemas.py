import re
from pydantic import BaseModel, field_validator
from typing import Optional, List
from datetime import datetime

HEX_COLOR_REGEX = re.compile(r"^#(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$")


class CategoryResponse(BaseModel):
    id: int
    name: str
    color: str
    icon: Optional[str] = None
    type: str
    is_active: bool
    sort_order: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class CategoryCreate(BaseModel):
    name: str
    color: Optional[str] = "#9E9E9E"
    icon: Optional[str] = None
    type: Optional[str] = "expense"
    sort_order: Optional[int] = 0

    @field_validator("color")
    @classmethod
    def validate_color(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and not HEX_COLOR_REGEX.match(v):
            raise ValueError("Invalid HEX color format")
        return v

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in ("expense", "income"):
            raise ValueError("Type must be 'expense' or 'income'")
        return v


class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    color: Optional[str] = None
    icon: Optional[str] = None
    type: Optional[str] = None
    is_active: Optional[bool] = None
    sort_order: Optional[int] = None

    @field_validator("color")
    @classmethod
    def validate_color(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and not HEX_COLOR_REGEX.match(v):
            raise ValueError("Invalid HEX color format")
        return v

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in ("expense", "income"):
            raise ValueError("Type must be 'expense' or 'income'")
        return v


class CategoryReorder(BaseModel):
    """Bulk reorder: list of {id, sort_order} pairs."""
    items: List[dict]
