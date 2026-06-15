from sqlalchemy.orm import Session
from app.models import User, Notification, UserNotification
from app.websocket_manager import manager
import logging

logger = logging.getLogger(__name__)

async def create_notification(
    db: Session,
    title: str,
    message: str,
    type: str = "info",
    priority: str = "normal",
    created_by: int = None,
    target_user_id: int = None,
    is_broadcast: bool = False
):
    try:
        # Create base notification
        notification = Notification(
            title=title,
            message=message,
            type=type,
            priority=priority,
            created_by=created_by,
            is_broadcast=is_broadcast
        )
        db.add(notification)
        db.commit()
        db.refresh(notification)

        user_ids = []
        if is_broadcast:
            # Query all user IDs
            users = db.query(User.id).all()
            user_ids = [u.id for u in users]
        elif target_user_id:
            user_ids = [target_user_id]

        # Insert UserNotification links
        for u_id in user_ids:
            user_notification = UserNotification(
                user_id=u_id,
                notification_id=notification.id,
                is_read=False
            )
            db.add(user_notification)
        db.commit()

        # Send real-time WebSockets update
        payload = {
            "event": "new_notification",
            "data": {
                "id": notification.id,
                "title": notification.title,
                "message": notification.message,
                "type": notification.type,
                "priority": notification.priority,
                "created_at": notification.created_at.isoformat(),
                "is_broadcast": notification.is_broadcast
            }
        }

        if is_broadcast:
            await manager.broadcast(payload)
        elif target_user_id:
            await manager.send_personal_message(payload, target_user_id)

        return notification
    except Exception as e:
        logger.error(f"Error creating notification: {e}")
        try:
            db.rollback()
        except Exception:
            pass
        return None  # Notification failure is non-fatal


async def check_and_trigger_balance_warning(db: Session, user_id: int, currency: str):
    from sqlalchemy import func
    from app.models import Expense, Income, Transfer

    try:
        # Sum Incomes
        income_sum = db.query(func.sum(Income.amount)).filter(
            Income.user_id == user_id,
            Income.currency == currency
        ).scalar() or 0.0

        # Sum Expenses
        expense_sum = db.query(func.sum(Expense.amount)).filter(
            Expense.user_id == user_id,
            Expense.currency == currency
        ).scalar() or 0.0

        # Sum Transfers Out
        trans_out_sum = db.query(func.sum(Transfer.amount_from)).filter(
            Transfer.user_id == user_id,
            Transfer.currency_from == currency
        ).scalar() or 0.0

        # Sum Transfers In
        trans_in_sum = db.query(func.sum(Transfer.amount_to)).filter(
            Transfer.user_id == user_id,
            Transfer.currency_to == currency
        ).scalar() or 0.0

        net_balance = float(income_sum) - float(expense_sum) - float(trans_out_sum) + float(trans_in_sum)
        if net_balance < 0:
            await create_notification(
                db=db,
                title="Low Balance Warning",
                message=f"Your {currency} balance is now negative ({net_balance:.2f} {currency})",
                type="warning",
                priority="high",
                target_user_id=user_id
            )
    except Exception as e:
        logger.error(f"Error checking balance for warning: {e}")

