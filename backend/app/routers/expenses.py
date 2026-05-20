from fastapi import APIRouter, Depends, HTTPException, status, Query, File, UploadFile
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import uuid
import os
import shutil

from app.database import get_db
from app.schemas import ExpenseCreate, ExpenseResponse, ExpenseBase
from app.models import Expense, User, RoleEnum
from app.auth import get_current_user
from app.utils.notification_helper import create_notification, check_and_trigger_balance_warning

router = APIRouter(prefix="/api/expenses", tags=["expenses"])

CATEGORIES = [
    "Travel", "Worship committee", "Volunteers committee", "Technical committee",
    "Protocol committee", "Invasion", "Zones", "BOA,ECC,APM", "Youth committee",
    "Woman committee", "Prayer committee", "Church Mobilization", "Promo",
    "Food & Drinks", "Accommodation", "Transfer", "Hospitality", "Permits",
    "Appreciation", "Internet/Phone", "Print", "Committees", "Other"
]

@router.get("/categories", response_model=List[str])
def get_categories():
    return CATEGORIES

@router.post("/upload-receipt", response_model=dict)
def upload_receipt(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    file_ext = os.path.splitext(file.filename)[1].lower()
    if file_ext not in [".jpg", ".jpeg", ".png", ".gif", ".webp"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Only image files (JPG, PNG, GIF, WEBP) are allowed."
        )
    
    unique_filename = f"{uuid.uuid4()}{file_ext}"
    file_path = os.path.join("uploads", unique_filename)
    
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Could not save file: {str(e)}"
        )
        
    return {"photo_url": f"/uploads/{unique_filename}"}

@router.get("", response_model=List[ExpenseResponse])
def get_expenses(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    category: Optional[str] = None,
    user_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Expense)
    
    # Permission check: normal users can only see their own
    if current_user.role == RoleEnum.user:
        query = query.filter(Expense.user_id == current_user.id)
    else:
        # Admins/Superadmins can filter by user_id
        if user_id is not None:
            query = query.filter(Expense.user_id == user_id)
            
    if start_date:
        query = query.filter(Expense.date >= start_date)
    if end_date:
        query = query.filter(Expense.date <= end_date)
    if category:
        query = query.filter(Expense.category == category)
        
    return query.order_by(Expense.date.desc()).all()

@router.post("", response_model=ExpenseResponse, status_code=status.HTTP_201_CREATED)
async def create_expense(
    expense_in: ExpenseCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_expense = Expense(**expense_in.model_dump(), user_id=current_user.id)
    db.add(new_expense)
    db.commit()
    db.refresh(new_expense)
    
    await create_notification(
        db=db,
        title="New Expense Added",
        message=f"You added a new expense: {new_expense.category} — {new_expense.amount} {new_expense.currency.value}",
        type="expense",
        priority="normal",
        target_user_id=current_user.id
    )
    
    await check_and_trigger_balance_warning(db, current_user.id, new_expense.currency.value)
    
    return new_expense

@router.put("/{expense_id}", response_model=ExpenseResponse)
def update_expense(
    expense_id: int,
    expense_in: ExpenseBase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    expense_query = db.query(Expense).filter(Expense.id == expense_id)
    expense = expense_query.first()
    
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
        
    if current_user.role == RoleEnum.user and expense.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this expense")
        
    expense_query.update(expense_in.model_dump(), synchronize_session=False)
    db.commit()
    return expense_query.first()

@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_expense(
    expense_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    expense = db.query(Expense).filter(Expense.id == expense_id).first()
    
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
        
    if current_user.role == RoleEnum.user and expense.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this expense")
        
    db.delete(expense)
    db.commit()
