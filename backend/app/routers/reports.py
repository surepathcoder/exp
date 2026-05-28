from fastapi import APIRouter, Depends, HTTPException, status, Query, Response
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.database import get_db
from app.models import Expense, Income, Transfer, User, RoleEnum, Project
from app.auth import get_current_user
from app.routers.expenses import _get_filtered_expenses_query
from app.utils.report_pdf_helper import generate_pdf_report
from app.utils.report_csv_helper import generate_csv_report

router = APIRouter(prefix="/api/reports", tags=["reports"])

def _get_incomes_query(db: Session, current_user: User, start_date, end_date, user_id, project=None):
    query = db.query(Income)
    if current_user.role == RoleEnum.user:
        query = query.filter(Income.user_id == current_user.id)
    elif user_id is not None:
        query = query.filter(Income.user_id == user_id)
    if start_date:
        query = query.filter(Income.date >= start_date)
    if end_date:
        query = query.filter(Income.date <= end_date)
    if project:
        query = query.join(Income.project_relation).filter(Project.name.in_(project))
    return query

def _get_transfers_query(db: Session, current_user: User, start_date, end_date, user_id, project=None):
    query = db.query(Transfer)
    if current_user.role == RoleEnum.user:
        query = query.filter(Transfer.user_id == current_user.id)
    elif user_id is not None:
        query = query.filter(Transfer.user_id == user_id)
    if start_date:
        query = query.filter(Transfer.date >= start_date)
    if end_date:
        query = query.filter(Transfer.date <= end_date)
    if project:
        query = query.join(Transfer.project_relation).filter(Project.name.in_(project))
    return query

def _get_report_data(db: Session, current_user: User, report_type, start_date, end_date, category, user_id, project, search):
    expenses, incomes, transfers = [], [], []
    
    if report_type in ['combined', 'expenses']:
        expenses = _get_filtered_expenses_query(
            db, current_user, start_date, end_date, category, user_id, search=search, project=project
        ).all()
        
    if report_type in ['combined', 'incomes']:
        incomes = _get_incomes_query(db, current_user, start_date, end_date, user_id, project=project).all()
        
    if report_type in ['combined', 'transfers']:
        transfers = _get_transfers_query(db, current_user, start_date, end_date, user_id, project=project).all()
        
    return expenses, incomes, transfers

@router.get("/preview")
def get_report_preview(
    report_type: str = "combined",
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    category: Optional[List[str]] = Query(None),
    user_id: Optional[int] = None,
    project: Optional[List[str]] = Query(None),
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    expenses, incomes, transfers = _get_report_data(
        db, current_user, report_type, start_date, end_date, category, user_id, project, search
    )
    
    # Calculate sums grouped by currency
    currencies = ["USD", "TZS", "KES"]
    summary = {curr: {"inflow": 0.0, "outflow": 0.0, "net": 0.0} for curr in currencies}
    
    for inc in incomes:
        c = inc.currency.value if hasattr(inc.currency, 'value') else str(inc.currency)
        if c in summary:
            summary[c]["inflow"] += float(inc.amount)
            summary[c]["net"] += float(inc.amount)
            
    for exp in expenses:
        c = exp.currency.value if hasattr(exp.currency, 'value') else str(exp.currency)
        if c in summary:
            summary[c]["outflow"] += float(exp.amount)
            summary[c]["net"] -= float(exp.amount)
            
    # Compile a preview list (max 5 records)
    preview_items = []
    for inc in incomes:
        preview_items.append({
            "type": "income",
            "date": inc.date.isoformat() if inc.date else None,
            "amount": float(inc.amount),
            "currency": inc.currency.value if hasattr(inc.currency, 'value') else str(inc.currency),
            "category_source": inc.source or "Income",
            "user": inc.owner.name if inc.owner else "Unknown",
            "details": inc.note or ""
        })
    for exp in expenses:
        preview_items.append({
            "type": "expense",
            "date": exp.date.isoformat() if exp.date else None,
            "amount": float(exp.amount),
            "currency": exp.currency.value if hasattr(exp.currency, 'value') else str(exp.currency),
            "category_source": exp.category or "Expense",
            "user": exp.owner.name if exp.owner else "Unknown",
            "details": f"{exp.note or ''} | Proj: {exp.project or ''}"
        })
    for tx in transfers:
        c_from = tx.currency_from.value if hasattr(tx.currency_from, 'value') else str(tx.currency_from)
        c_to = tx.currency_to.value if hasattr(tx.currency_to, 'value') else str(tx.currency_to)
        preview_items.append({
            "type": "transfer",
            "date": tx.date.isoformat() if tx.date else None,
            "amount": float(tx.amount_from),
            "currency": f"{c_from}->{c_to}",
            "category_source": "Transfer",
            "user": tx.owner.name if tx.owner else "Unknown",
            "details": f"Exchanged to {float(tx.amount_to):,.2f} {c_to} | {tx.note or ''}"
        })
        
    preview_items.sort(key=lambda x: x["date"] or "", reverse=True)
    
    return {
        "report_type": report_type,
        "summary": summary,
        "counts": {
            "expenses": len(expenses),
            "incomes": len(incomes),
            "transfers": len(transfers),
            "total": len(expenses) + len(incomes) + len(transfers)
        },
        "preview": preview_items[:5]
    }

@router.get("/export/pdf")
def export_report_pdf(
    report_type: str = "combined",
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    category: Optional[List[str]] = Query(None),
    user_id: Optional[int] = None,
    project: Optional[List[str]] = Query(None),
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    expenses, incomes, transfers = _get_report_data(
        db, current_user, report_type, start_date, end_date, category, user_id, project, search
    )
    
    user_desc = current_user.name if current_user.role == RoleEnum.user else (
        db.query(User).filter(User.id == user_id).first().name if user_id else "All Users"
    )
    date_range = f"{start_date.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')}" if (start_date and end_date) else (
        f"From {start_date.strftime('%Y-%m-%d')}" if start_date else (
            f"To {end_date.strftime('%Y-%m-%d')}" if end_date else "All Dates"
        )
    )
    
    filters_desc = {
        "date_range": date_range,
        "category": ", ".join(category) if category else None,
        "project": ", ".join(project) if project else None,
        "user": user_desc
    }
    
    pdf_bytes = generate_pdf_report(report_type, expenses, incomes, transfers, filters_desc)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename=financial_report_{report_type}.pdf"}
    )

@router.get("/export/csv")
def export_report_csv(
    report_type: str = "combined",
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    category: Optional[List[str]] = Query(None),
    user_id: Optional[int] = None,
    project: Optional[List[str]] = Query(None),
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    expenses, incomes, transfers = _get_report_data(
        db, current_user, report_type, start_date, end_date, category, user_id, project, search
    )
    csv_str = generate_csv_report(report_type, expenses, incomes, transfers)
    return Response(
        content=csv_str,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=financial_report_{report_type}.csv"}
    )
