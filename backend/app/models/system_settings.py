from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Enum, CheckConstraint, JSON
from datetime import datetime
from app.database import Base
from app.models.core import CurrencyEnum


class SystemSettings(Base):
    """Singleton system settings — enforced by CHECK(id=1) constraint."""
    __tablename__ = "system_settings"
    __table_args__ = (
        CheckConstraint("id = 1", name="singleton_settings_check"),
    )

    id = Column(Integer, primary_key=True, default=1)
    app_name = Column(String, default="Expense Tracker", nullable=False)
    default_currency = Column(Enum(CurrencyEnum), default=CurrencyEnum.USD, nullable=False)
    use_live_rates = Column(Boolean, default=True, nullable=False)
    manual_rates = Column(JSON, nullable=True)
    session_timeout_minutes = Column(Integer, default=1440, nullable=False)
    notification_defaults = Column(JSON, nullable=True)
    version = Column(Integer, default=1, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    updated_by = Column(Integer, ForeignKey("users.id"), nullable=True)
