from sqlalchemy import Column, Integer, String, Numeric, Enum, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from app.database import Base
from app.models.core import CurrencyEnum

class ProjectStatusEnum(str, enum.Enum):
    upcoming = "upcoming"
    active = "active"
    completed = "completed"
    expired = "expired"
    cancelled = "cancelled"

class Project(Base):
    __tablename__ = "projects"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    budget = Column(Numeric(18, 2), nullable=True)
    currency = Column(Enum(CurrencyEnum), default=CurrencyEnum.USD, nullable=False)
    status = Column(Enum(ProjectStatusEnum), default=ProjectStatusEnum.active, nullable=False)
    start_date = Column(DateTime, nullable=True)
    end_date = Column(DateTime, nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    creator = relationship("User", foreign_keys=[user_id])
    expenses = relationship("Expense", back_populates="project_relation", foreign_keys="Expense.project_id")
    incomes = relationship("Income", back_populates="project_relation", foreign_keys="Income.project_id")
    transfers = relationship("Transfer", back_populates="project_relation", foreign_keys="Transfer.project_id")
