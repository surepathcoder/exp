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
    TZS = "TZS"
    KES = "KES"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(Enum(RoleEnum), default=RoleEnum.user, nullable=False)
    is_approved = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    reset_token = Column(String, nullable=True)
    reset_token_expires = Column(DateTime, nullable=True)

    expenses = relationship("Expense", back_populates="owner", cascade="all, delete-orphan")
    incomes = relationship("Income", back_populates="owner", cascade="all, delete-orphan")
    transfers = relationship("Transfer", back_populates="owner", cascade="all, delete-orphan")
    created_notifications = relationship(
        "Notification", foreign_keys="Notification.created_by", back_populates="creator"
    )
    user_notifications = relationship("UserNotification", back_populates="user", cascade="all, delete-orphan")


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
    vendor = Column(String, nullable=True)
    project = Column(String, nullable=True)
    photo_url = Column(String, nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="expenses")


class Income(Base):
    __tablename__ = "incomes"

    id = Column(Integer, primary_key=True, index=True)
    amount = Column(Float, nullable=False)
    currency = Column(Enum(CurrencyEnum), nullable=False)
    source = Column(String, nullable=False)
    date = Column(DateTime, nullable=False)
    note = Column(String, nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="incomes")


class Transfer(Base):
    __tablename__ = "transfers"

    id = Column(Integer, primary_key=True, index=True)
    amount_from = Column(Float, nullable=False)
    currency_from = Column(Enum(CurrencyEnum), nullable=False)
    amount_to = Column(Float, nullable=False)
    currency_to = Column(Enum(CurrencyEnum), nullable=False)
    date = Column(DateTime, nullable=False)
    note = Column(String, nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="transfers")
