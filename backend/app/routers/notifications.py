from fastapi import APIRouter, Depends, HTTPException, status, WebSocket
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from jose import jwt, JWTError

from app.database import get_db
from app.models import User, UserNotification, Notification, RoleEnum
from app.schemas import UserNotificationResponse, UnreadCountResponse, NotificationCreate
from app.auth import get_current_user, get_current_superadmin
from app.websocket_manager import manager
from app.utils.notification_helper import create_notification
from app.config import settings

router = APIRouter(prefix="/api", tags=["notifications"])

@router.get("/notifications", response_model=List[UserNotificationResponse])
def get_user_notifications(
    is_read: Optional[bool] = None,
    limit: int = 20,
    offset: int = 0,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(UserNotification).filter(UserNotification.user_id == current_user.id)
    if is_read is not None:
        query = query.filter(UserNotification.is_read == is_read)
    
    # Order by unread first, then by date created
    query = query.join(Notification).order_by(
        UserNotification.is_read.asc(),
        Notification.created_at.desc()
    )
    
    return query.offset(offset).limit(limit).all()

@router.get("/notifications/unread-count", response_model=UnreadCountResponse)
def get_unread_count(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    count = db.query(UserNotification).filter(
        UserNotification.user_id == current_user.id,
        UserNotification.is_read == False
    ).count()
    return {"count": count}

@router.put("/notifications/read")
def mark_notifications_as_read(
    notification_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if notification_id is not None:
        user_notif = db.query(UserNotification).filter(
            UserNotification.notification_id == notification_id,
            UserNotification.user_id == current_user.id
        ).first()
        if not user_notif:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Notification not found"
            )
        user_notif.is_read = True
        user_notif.read_at = datetime.utcnow()
    else:
        unread = db.query(UserNotification).filter(
            UserNotification.user_id == current_user.id,
            UserNotification.is_read == False
        ).all()
        for u in unread:
            u.is_read = True
            u.read_at = datetime.utcnow()
            
    db.commit()
    return {"status": "success", "message": "Notifications marked as read"}

@router.post("/admin/notifications", status_code=status.HTTP_201_CREATED)
async def admin_create_notification(
    notification_in: NotificationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superadmin)
):
    # Verify that either is_broadcast is true or target_user_id is provided
    if not notification_in.is_broadcast and not notification_in.target_user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Must specify target_user_id or set is_broadcast to True"
        )
        
    await create_notification(
        db=db,
        title=notification_in.title,
        message=notification_in.message,
        type=notification_in.type,
        priority=notification_in.priority,
        created_by=current_user.id,
        target_user_id=notification_in.target_user_id,
        is_broadcast=notification_in.is_broadcast
    )
    return {"status": "success", "message": "Notification dispatched"}

@router.websocket("/notifications/ws")
async def websocket_endpoint(websocket: WebSocket, token: Optional[str] = None):
    if not token:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return
        
    db = next(get_db())
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email = payload.get("sub")
        if email is None:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
            
        user = db.query(User).filter(User.email == email).first()
        if user is None:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
            
        await manager.connect(user.id, websocket)
        try:
            while True:
                # Keep connection alive by listening for client messages
                await websocket.receive_text()
        except Exception:
            pass
        finally:
            manager.disconnect(user.id, websocket)
    except JWTError:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
    finally:
        db.close()
