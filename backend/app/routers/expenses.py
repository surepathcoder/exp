from fastapi import APIRouter, Depends, HTTPException, status, Query, File, UploadFile, Response
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from typing import List, Optional
from datetime import datetime
import uuid
import os
import shutil

from app.database import get_db
from app.schemas import ExpenseCreate, ExpenseResponse, ExpenseBase
from app.models import Expense, User, RoleEnum, Project, ProjectStatusEnum
from app.models.wallet import Wallet
from app.auth import get_current_user
from app.utils.notification_helper import create_notification, check_and_trigger_balance_warning
from app.utils.export_helpers import generate_csv, generate_pdf
from app.utils.wallet_sync import sync_wallet_balance

def _validate_wallet_currency(db: Session, wallet_id: Optional[int], transaction_currency: str, current_user: User):
    if wallet_id is None:
        return
    wallet = db.query(Wallet).filter(Wallet.id == wallet_id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")
    if current_user.role == RoleEnum.user and wallet.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to use this wallet")
    if not wallet.is_active:
        raise HTTPException(status_code=400, detail="Wallet is archived and cannot receive new transactions")
    w_curr = wallet.currency.value if hasattr(wallet.currency, 'value') else str(wallet.currency)
    if w_curr != transaction_currency:
        raise HTTPException(
            status_code=400,
            detail=f"Transaction currency {transaction_currency} does not match wallet currency {w_curr}"
        )


router = APIRouter(prefix="/api/expenses", tags=["expenses"])

CATEGORIES = [
    "Travel", "Worship committee", "Volunteers committee", "Technical committee",
    "Protocol committee", "Invasion", "Zones", "BOA,ECC,APM", "Youth committee",
    "Woman committee", "Prayer committee", "Church Mobilization", "Promo",
    "Food & Drinks", "Accommodation", "Transfer", "Hospitality", "Permits",
    "Appreciation", "Internet/Phone", "Print", "Committees", "Other"
]

@router.get("/categories", response_model=List[str])
def get_categories(db: Session = Depends(get_db)):
    from app.models import Category
    cats = db.query(Category.name).filter(Category.is_active == True, Category.type == "expense").order_by(Category.sort_order.asc()).all()
    if cats:
        return [c[0] for c in cats]
    return CATEGORIES

@router.post("/upload-receipt", response_model=dict)
def upload_receipt(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    file_ext = os.path.splitext(file.filename)[1].lower()
    if file_ext not in [".jpg", ".jpeg", ".png", ".gif", ".webp", ".pdf"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Only image files (JPG, PNG, GIF, WEBP) and PDF files are allowed."
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

def _get_filtered_expenses_query(
    db: Session,
    current_user: User,
    start_date: Optional[datetime],
    end_date: Optional[datetime],
    categories: Optional[List[str]],
    user_id: Optional[int],
    search: Optional[str] = None,
    min_amount: Optional[float] = None,
    max_amount: Optional[float] = None,
    status: Optional[str] = None,
    project: Optional[List[str]] = None,
    project_id: Optional[int] = None
):
    query = db.query(Expense)
    if current_user.role == RoleEnum.user:
        query = query.filter(Expense.user_id == current_user.id)
    else:
        if user_id is not None:
            query = query.filter(Expense.user_id == user_id)
            
    if start_date:
        query = query.filter(Expense.date >= start_date)
    if end_date:
        query = query.filter(Expense.date <= end_date)
    if categories:
        query = query.filter(Expense.category.in_(categories))
    if project:
        query = query.join(Expense.project_relation).filter(Project.name.in_(project))
    if project_id is not None:
        query = query.filter(Expense.project_id == project_id)
    if min_amount is not None:
        query = query.filter(Expense.amount >= min_amount)
    if max_amount is not None:
        query = query.filter(Expense.amount <= max_amount)
    if search:
        search_pattern = f"%{search}%"
        query = query.outerjoin(Expense.project_relation).filter(
            or_(
                Expense.note.ilike(search_pattern),
                Expense.vendor.ilike(search_pattern),
                Expense.payment_method.ilike(search_pattern),
                Expense.location.ilike(search_pattern),
                Expense.category.ilike(search_pattern),
                Project.name.ilike(search_pattern)
            )
        )
    if status and status != "all":
        if status == "has_receipt":
            query = query.filter(
                or_(
                    Expense.is_self_receipt == True,
                    and_(Expense.photo_url != None, Expense.photo_url != "")
                )
            )
        elif status == "missing_receipt":
            query = query.filter(
                and_(
                    Expense.is_self_receipt == False,
                    or_(Expense.photo_url == None, Expense.photo_url == "")
                )
            )
        elif status == "self_receipt":
            query = query.filter(Expense.is_self_receipt == True)
        elif status == "standard_receipt":
            query = query.filter(
                and_(
                    Expense.is_self_receipt == False,
                    and_(Expense.photo_url != None, Expense.photo_url != "")
                )
            )
        
    return query.order_by(Expense.date.desc())

@router.get("", response_model=List[ExpenseResponse])
def get_expenses(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    category: Optional[List[str]] = Query(None),
    user_id: Optional[int] = None,
    search: Optional[str] = None,
    min_amount: Optional[float] = None,
    max_amount: Optional[float] = None,
    status: Optional[str] = None,
    project: Optional[List[str]] = Query(None),
    project_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = _get_filtered_expenses_query(
        db, current_user, start_date, end_date, category, user_id,
        search, min_amount, max_amount, status, project, project_id
    )
    return query.offset(skip).limit(limit).all()

@router.get("/export/csv")
def export_expenses_csv(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    category: Optional[List[str]] = Query(None),
    user_id: Optional[int] = None,
    search: Optional[str] = None,
    min_amount: Optional[float] = None,
    max_amount: Optional[float] = None,
    status: Optional[str] = None,
    project: Optional[List[str]] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = _get_filtered_expenses_query(
        db, current_user, start_date, end_date, category, user_id,
        search, min_amount, max_amount, status, project
    )
    expenses = query.all()
    csv_data = generate_csv(expenses)
    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=expenses_report.csv"}
    )

@router.get("/export/pdf")
def export_expenses_pdf(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    category: Optional[List[str]] = Query(None),
    user_id: Optional[int] = None,
    search: Optional[str] = None,
    min_amount: Optional[float] = None,
    max_amount: Optional[float] = None,
    status: Optional[str] = None,
    project: Optional[List[str]] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = _get_filtered_expenses_query(
        db, current_user, start_date, end_date, category, user_id,
        search, min_amount, max_amount, status, project
    )
    expenses = query.all()
    
    # Get user descriptor
    user_desc = None
    if current_user.role == RoleEnum.user:
        user_desc = current_user.name
    elif user_id is not None:
        selected_user = db.query(User).filter(User.id == user_id).first()
        if selected_user:
            user_desc = selected_user.name
            
    # Format filters description
    date_range = None
    if start_date and end_date:
        date_range = f"{start_date.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')}"
    elif start_date:
        date_range = f"From {start_date.strftime('%Y-%m-%d')}"
    elif end_date:
        date_range = f"To {end_date.strftime('%Y-%m-%d')}"
        
    filters_desc = {
        "date_range": date_range,
        "category": ", ".join(category) if category else None,
        "project": ", ".join(project) if project else None,
        "user": user_desc
    }
    
    pdf_bytes = generate_pdf(expenses, filters_desc)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": "attachment; filename=expenses_report.pdf"}
    )


@router.post("", response_model=ExpenseResponse, status_code=status.HTTP_201_CREATED)
async def create_expense(
    expense_in: ExpenseCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    _validate_wallet_currency(db, expense_in.wallet_id, expense_in.currency.value, current_user)
    
    # Project validation
    if expense_in.project_id is not None:
        project = db.query(Project).filter(Project.id == expense_in.project_id).first()
        if not project:
            raise HTTPException(status_code=400, detail="Selected project does not exist")
        if project.status in [ProjectStatusEnum.completed, ProjectStatusEnum.expired, ProjectStatusEnum.cancelled]:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot attach transactions to a project with status '{project.status.value}'"
            )

    expense_data = expense_in.model_dump()
    expense_data.pop("project", None)
    new_expense = Expense(**expense_data, user_id=current_user.id)
    db.add(new_expense)
    db.commit()
    db.refresh(new_expense)
    
    if new_expense.wallet_id:
        sync_wallet_balance(db, new_expense.wallet_id)
        
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


@router.get("/{expense_id}", response_model=ExpenseResponse)
def get_expense(
    expense_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    expense = db.query(Expense).filter(Expense.id == expense_id).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
        
    if current_user.role == RoleEnum.user and expense.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this expense")
        
    return expense


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
        
    old_wallet_id = expense.wallet_id
    _validate_wallet_currency(db, expense_in.wallet_id, expense_in.currency.value, current_user)
    
    # Project validation
    if expense_in.project_id is not None:
        project = db.query(Project).filter(Project.id == expense_in.project_id).first()
        if not project:
            raise HTTPException(status_code=400, detail="Selected project does not exist")
        if project.status in [ProjectStatusEnum.completed, ProjectStatusEnum.expired, ProjectStatusEnum.cancelled]:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot attach transactions to a project with status '{project.status.value}'"
            )

    expense_data = expense_in.model_dump()
    expense_data.pop("project", None)
    expense_query.update(expense_data, synchronize_session=False)
    db.commit()
    
    if expense_in.wallet_id:
        sync_wallet_balance(db, expense_in.wallet_id)
    if old_wallet_id and old_wallet_id != expense_in.wallet_id:
        sync_wallet_balance(db, old_wallet_id)
        
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
        
    wallet_id = expense.wallet_id
    db.delete(expense)
    db.commit()
    
    if wallet_id:
        sync_wallet_balance(db, wallet_id)
