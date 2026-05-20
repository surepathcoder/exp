from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    type = Column(String, nullable=False, default="info")
    priority = Column(String, nullable=False, default="normal")
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    is_broadcast = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    creator = relationship("User", foreign_keys=[created_by], back_populates="created_notifications")
    user_notifications = relationship(
        "UserNotification", back_populates="notification", cascade="all, delete-orphan"
    )


class UserNotification(Base):
    __tablename__ = "user_notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    notification_id = Column(Integer, ForeignKey("notifications.id"), nullable=False)
    is_read = Column(Boolean, default=False)
    read_at = Column(DateTime, nullable=True)

    user = relationship("User", back_populates="user_notifications")
    notification = relationship("Notification", back_populates="user_notifications")
