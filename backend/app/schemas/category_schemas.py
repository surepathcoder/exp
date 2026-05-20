from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class CategoryResponse(BaseModel):
    id: int
    name: str
    is_active: bool
    sort_order: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class CategoryCreate(BaseModel):
    name: str
    sort_order: Optional[int] = 0


class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    is_active: Optional[bool] = None
    sort_order: Optional[int] = None


class CategoryReorder(BaseModel):
    """Bulk reorder: list of {id, sort_order} pairs."""
    items: List[dict]
