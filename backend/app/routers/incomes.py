from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.database import get_db
from app.schemas import IncomeCreate, IncomeResponse, IncomeBase
from app.models import Income, User, RoleEnum
from app.auth import get_current_user
from app.utils.notification_helper import create_notification

router = APIRouter(prefix="/api/incomes", tags=["incomes"])

SOURCES = ["Salary", "Donation", "Investment", "Refund", "Other"]

@router.get("/sources", response_model=List[str])
def get_sources():
    return SOURCES

@router.get("", response_model=List[IncomeResponse])
def get_incomes(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    source: Optional[str] = None,
    user_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Income)
    
    # Permission check: normal users can only see their own
    if current_user.role == RoleEnum.user:
        query = query.filter(Income.user_id == current_user.id)
    else:
        # Admins/Superadmins can filter by user_id
        if user_id is not None:
            query = query.filter(Income.user_id == user_id)
            
    if start_date:
        query = query.filter(Income.date >= start_date)
    if end_date:
        query = query.filter(Income.date <= end_date)
    if source:
        query = query.filter(Income.source == source)
        
    return query.order_by(Income.date.desc()).all()

@router.post("", response_model=IncomeResponse, status_code=status.HTTP_201_CREATED)
async def create_income(
    income_in: IncomeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_income = Income(**income_in.model_dump(), user_id=current_user.id)
    db.add(new_income)
    db.commit()
    db.refresh(new_income)
    
    await create_notification(
        db=db,
        title="New Income Added",
        message=f"You received income: {new_income.source} — {new_income.amount} {new_income.currency.value}",
        type="income",
        priority="normal",
        target_user_id=current_user.id
    )
    
    return new_income

@router.put("/{income_id}", response_model=IncomeResponse)
def update_income(
    income_id: int,
    income_in: IncomeBase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    income_query = db.query(Income).filter(Income.id == income_id)
    income = income_query.first()
    
    if not income:
        raise HTTPException(status_code=404, detail="Income not found")
        
    if current_user.role == RoleEnum.user and income.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this income")
        
    income_query.update(income_in.model_dump(), synchronize_session=False)
    db.commit()
    return income_query.first()

@router.delete("/{income_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_income(
    income_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    income = db.query(Income).filter(Income.id == income_id).first()
    
    if not income:
        raise HTTPException(status_code=404, detail="Income not found")
        
    if current_user.role == RoleEnum.user and income.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this income")
        
    db.delete(income)
    db.commit()
