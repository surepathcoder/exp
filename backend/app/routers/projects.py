from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, func
from typing import List, Optional
from decimal import Decimal

from app.database import get_db
from app.schemas.project import ProjectCreate, ProjectUpdate, ProjectResponse, ProjectSummaryResponse
from app.models import User, RoleEnum
from app.models.project import Project, ProjectStatusEnum
from app.models.core import Expense, Income
from app.auth import get_current_user
from app.routers.dashboard import get_rates_with_settings

router = APIRouter(prefix="/api/projects", tags=["projects"])


def convert_currency(amount: Decimal, from_curr: str, to_curr: str, rates: dict) -> Decimal:
    """Helper to convert amount between currencies using USD as base."""
    if from_curr == to_curr:
        return amount
    
    # Convert to USD first
    rate_from = Decimal(str(rates.get(from_curr, 1.0)))
    usd_amount = amount / rate_from
    
    # Convert USD to target
    rate_to = Decimal(str(rates.get(to_curr, 1.0)))
    return usd_amount * rate_to


@router.get("", response_model=List[ProjectResponse])
def get_projects(
    status: Optional[ProjectStatusEnum] = None,
    active_only: bool = False,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(Project)
    
    # Normal users can only see their own projects? Wait! Events/Projects are usually organization-wide!
    # In Odoo/Zoho, events/projects are visible to all approved users so they can log expenses against them.
    # So we don't strictly filter by user_id for list, which is standard! But let's allow it.
    
    if active_only:
        query = query.filter(Project.status.in_([ProjectStatusEnum.active, ProjectStatusEnum.upcoming]))
    elif status:
        query = query.filter(Project.status == status)
        
    if search:
        search_pattern = f"%{search}%"
        query = query.filter(
            or_(
                Project.name.ilike(search_pattern),
                Project.description.ilike(search_pattern)
            )
        )
        
    return query.order_by(Project.created_at.desc()).all()


@router.post("", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
def create_project(
    project_in: ProjectCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Only Admin / Superadmin should create projects? 
    # Requirement: "Users should create a Project once, then attach many transactions to it."
    # We allow all users to create projects, or at least normal users. Let's allow everyone.
    new_project = Project(**project_in.model_dump(), user_id=current_user.id)
    db.add(new_project)
    db.commit()
    db.refresh(new_project)
    return new_project


@router.get("/{project_id}", response_model=ProjectResponse)
def get_project(
    project_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    project = db.query(Project).filter(Project.id == project_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    return project


@router.get("/{project_id}/summary", response_model=ProjectSummaryResponse)
def get_project_summary(
    project_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    project = db.query(Project).filter(Project.id == project_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
        
    rates = get_rates_with_settings(db)
    proj_currency = project.currency.value if hasattr(project.currency, 'value') else str(project.currency)
    
    # Calculate total expenses linked to project (with currency conversion!)
    expenses = db.query(Expense).filter(Expense.project_id == project_id).all()
    total_expenses = Decimal("0.00")
    for exp in expenses:
        exp_curr = exp.currency.value if hasattr(exp.currency, 'value') else str(exp.currency)
        converted = convert_currency(Decimal(str(exp.amount)), exp_curr, proj_currency, rates)
        total_expenses += converted
        
    # Calculate total incomes linked to project (with currency conversion!)
    incomes = db.query(Income).filter(Income.project_id == project_id).all()
    total_incomes = Decimal("0.00")
    for inc in incomes:
        inc_curr = inc.currency.value if hasattr(inc.currency, 'value') else str(inc.currency)
        converted = convert_currency(Decimal(str(inc.amount)), inc_curr, proj_currency, rates)
        total_incomes += converted
        
    # Remaining balance (project budget - total expenses + total incomes? Or just budget - expenses?
    # Usually: budget - total expenses is the remaining project budget/balance. Let's do remaining budget!)
    proj_budget = project.budget if project.budget is not None else Decimal("0.00")
    remaining_balance = proj_budget - total_expenses
    
    # Pack response
    summary = ProjectSummaryResponse(
        id=project.id,
        name=project.name,
        description=project.description,
        budget=project.budget,
        currency=project.currency,
        status=project.status,
        start_date=project.start_date,
        end_date=project.end_date,
        user_id=project.user_id,
        created_at=project.created_at,
        total_expenses=total_expenses,
        total_incomes=total_incomes,
        remaining_balance=remaining_balance
    )
    return summary


@router.put("/{project_id}", response_model=ProjectResponse)
def update_project(
    project_id: int,
    project_in: ProjectUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    project_query = db.query(Project).filter(Project.id == project_id)
    project = project_query.first()
    
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
        
    # Only project creator or admins can update? Standard check.
    if current_user.role == RoleEnum.user and project.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this project")
        
    # Enforce read-only for completed, expired, or cancelled projects
    if project.status in [ProjectStatusEnum.completed, ProjectStatusEnum.expired, ProjectStatusEnum.cancelled]:
        update_dict = project_in.model_dump(exclude_unset=True)
        if any(k != 'status' for k in update_dict.keys()):
            raise HTTPException(
                status_code=400,
                detail="Completed, expired, or cancelled projects are read-only and cannot be modified."
            )
            
    project_query.update(project_in.model_dump(exclude_unset=True), synchronize_session=False)
    db.commit()
    return project_query.first()


@router.delete("/{project_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_project(
    project_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    project = db.query(Project).filter(Project.id == project_id).first()
    
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
        
    if current_user.role == RoleEnum.user and project.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this project")
        
    # Prevent deletion if transactions are attached
    expenses_count = db.query(Expense).filter(Expense.project_id == project_id).count()
    incomes_count = db.query(Income).filter(Income.project_id == project_id).count()
    if expenses_count > 0 or incomes_count > 0:
        raise HTTPException(
            status_code=400,
            detail="Cannot delete project that contains expenses or income records. Archive it instead by setting status to expired or completed."
        )
        
    db.delete(project)
    db.commit()
