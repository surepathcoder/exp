from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from decimal import Decimal
from app.models.project import ProjectStatusEnum
from app.models.core import CurrencyEnum

class ProjectBase(BaseModel):
    name: str
    description: Optional[str] = None
    budget: Optional[Decimal] = None
    currency: CurrencyEnum = CurrencyEnum.USD
    status: ProjectStatusEnum = ProjectStatusEnum.active
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None

class ProjectCreate(ProjectBase):
    pass

class ProjectUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    budget: Optional[Decimal] = None
    currency: Optional[CurrencyEnum] = None
    status: Optional[ProjectStatusEnum] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None

class ProjectResponse(ProjectBase):
    id: int
    user_id: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True

class ProjectSummaryResponse(ProjectResponse):
    total_expenses: Decimal = Decimal("0.00")
    total_incomes: Decimal = Decimal("0.00")
    remaining_balance: Decimal = Decimal("0.00")

    class Config:
        from_attributes = True
