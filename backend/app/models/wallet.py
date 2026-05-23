import enum
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Enum, Numeric
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base
from app.models.core import CurrencyEnum

class WalletTypeEnum(str, enum.Enum):
    cash = "cash"
    bank = "bank"
    mobile_money = "mobile_money"
    credit_card = "credit_card"

class Wallet(Base):
    __tablename__ = "wallets"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    type = Column(Enum(WalletTypeEnum), default=WalletTypeEnum.cash, nullable=False)
    currency = Column(Enum(CurrencyEnum), nullable=False)
    opening_balance = Column(Numeric(18, 2), default=0.00, nullable=False)
    balance = Column(Numeric(18, 2), default=0.00, nullable=False)
    icon = Column(String, default="wallet", nullable=False)
    color = Column(String, default="#3D1B5B", nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("User", back_populates="wallets")
    expenses = relationship("Expense", back_populates="wallet")
    incomes = relationship("Income", back_populates="wallet")
    
    # We don't link transfers explicitly with back_populates to avoid multiple join paths conflict,
    # but we can query them using foreign keys.
