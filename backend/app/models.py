from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from app.database import Base

class RoleEnum(str, enum.Enum):
    superadmin = "superadmin"
    admin = "admin"
    user = "user"

class CurrencyEnum(str, enum.Enum):
    USD = "USD"
    CDF = "CDF"
    TZS = "TZS"
    UGX = "UGX"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(Enum(RoleEnum), default=RoleEnum.user, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    expenses = relationship("Expense", back_populates="owner", cascade="all, delete-orphan")

class Expense(Base):
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True, index=True)
    amount = Column(Float, nullable=False)
    currency = Column(Enum(CurrencyEnum), nullable=False)
    category = Column(String, nullable=False)
    date = Column(DateTime, nullable=False)
    note = Column(String, nullable=True)
    is_self_receipt = Column(Boolean, default=False)
    payment_method = Column(String, nullable=True)
    location = Column(String, nullable=True)
    photo_url = Column(String, nullable=True)
    
    user_id = Column(Integer, ForeignKey("users.id"))
    
    owner = relationship("User", back_populates="expenses")
