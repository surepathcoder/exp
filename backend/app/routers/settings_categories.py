"""Category management router."""
from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models import User
from app.auth import get_current_user, get_current_superadmin
from app.schemas import CategoryResponse, CategoryCreate, CategoryUpdate, CategoryReorder
from app.services import category_service

router = APIRouter(prefix="/api/settings/categories", tags=["categories"])


@router.get("", response_model=List[CategoryResponse])
def get_active_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List active categories — available to all authenticated users."""
    return category_service.get_active_categories(db)


@router.get("/all", response_model=List[CategoryResponse])
def get_all_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superadmin),
):
    """List ALL categories including inactive — SuperAdmin only."""
    return category_service.get_all_categories(db)


@router.post("", response_model=CategoryResponse)
def create_category(
    data: CategoryCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superadmin),
):
    ip = request.client.host if request.client else None
    return category_service.create_category(db, data, current_user, ip)


@router.put("/{cat_id}", response_model=CategoryResponse)
def update_category(
    cat_id: int,
    data: CategoryUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superadmin),
):
    ip = request.client.host if request.client else None
    return category_service.update_category(db, cat_id, data, current_user, ip)


@router.delete("/{cat_id}", response_model=CategoryResponse)
def delete_category(
    cat_id: int,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superadmin),
):
    """Soft-delete a category (sets is_active=False)."""
    ip = request.client.host if request.client else None
    return category_service.delete_category(db, cat_id, current_user, ip)


@router.put("/reorder", status_code=200)
def reorder_categories(
    data: CategoryReorder,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superadmin),
):
    ip = request.client.host if request.client else None
    category_service.reorder_categories(db, data.items, current_user, ip)
    return {"status": "ok"}
