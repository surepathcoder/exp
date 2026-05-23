from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from decimal import Decimal
from app.models.wallet import WalletTypeEnum
from app.models.core import CurrencyEnum

class WalletBase(BaseModel):
    name: str
    type: WalletTypeEnum
    currency: CurrencyEnum
    opening_balance: Decimal = Decimal('0.00')
    icon: str = "wallet"
    color: str = "#3D1B5B"

class WalletCreate(WalletBase):
    pass

class WalletUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[WalletTypeEnum] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    is_active: Optional[bool] = None

class WalletResponse(WalletBase):
    id: int
    balance: Decimal
    is_active: bool
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True
