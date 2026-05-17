from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import Dict
from sqlalchemy import func

from app.database import get_db
from app.models import Expense, User, RoleEnum
from app.auth import get_current_user

router = APIRouter(prefix="/api/dashboard", tags=["dashboard"])

@router.get("/balance", response_model=Dict[str, float])
def get_balance(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Expense.currency, func.sum(Expense.amount).label("total"))
    
    if current_user.role == RoleEnum.user:
        query = query.filter(Expense.user_id == current_user.id)
        
    results = query.group_by(Expense.currency).all()
    
    balances = {
        "USD": 0.0,
        "CDF": 0.0,
        "TZS": 0.0,
        "UGX": 0.0
    }
    
    for currency, total in results:
        if currency and total:
            balances[currency.value] = float(total)
            
    return balances

@router.get("/self-receipt-percentage")
def get_self_receipt_percentage(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Expense)
    
    if current_user.role == RoleEnum.user:
        query = query.filter(Expense.user_id == current_user.id)
        
    total_expenses = query.count()
    if total_expenses == 0:
        return {"percentage": 0.0}
        
    self_receipts = query.filter(Expense.is_self_receipt == True).count()
    
    percentage = (self_receipts / total_expenses) * 100
    return {"percentage": round(percentage, 1)}
