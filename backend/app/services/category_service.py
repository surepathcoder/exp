"""Category service — CRUD with soft-delete, ordering, and caching."""
from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.models import Category, User
from app.schemas import CategoryCreate, CategoryUpdate
from app.services.cache_service import cache
from app.services import audit_service

CACHE_KEY_ACTIVE = "categories_active"
CACHE_KEY_ALL = "categories_all"
CACHE_TTL = 300


PROTECTED_CATEGORIES = {"Other", "Uncategorized", "Salary", "Transfer"}


def _invalidate_caches():
    cache.invalidate(CACHE_KEY_ACTIVE)
    cache.invalidate(CACHE_KEY_ALL)


def get_active_categories(db: Session) -> list:
    cached = cache.get(CACHE_KEY_ACTIVE)
    if cached:
        return cached
    cats = db.query(Category).filter(Category.is_active == True).order_by(Category.sort_order).all()
    cache.set(CACHE_KEY_ACTIVE, cats, CACHE_TTL)
    return cats


def get_all_categories(db: Session) -> list:
    cached = cache.get(CACHE_KEY_ALL)
    if cached:
        return cached
    cats = db.query(Category).order_by(Category.sort_order).all()
    cache.set(CACHE_KEY_ALL, cats, CACHE_TTL)
    return cats


def create_category(db: Session, data: CategoryCreate, user: User, ip: str = None) -> Category:
    existing = db.query(Category).filter(Category.name == data.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Category already exists")
    cat = Category(
        name=data.name,
        sort_order=data.sort_order or 0,
        color=data.color or "#9E9E9E",
        icon=data.icon,
        type=data.type or "expense",
    )
    db.add(cat)
    db.commit()
    db.refresh(cat)
    _invalidate_caches()
    audit_service.log_change(
        db,
        user,
        "create_category",
        "category",
        str(cat.id),
        None,
        {"name": cat.name, "color": cat.color, "icon": cat.icon, "type": cat.type},
        ip
    )
    return cat


def update_category(db: Session, cat_id: int, data: CategoryUpdate, user: User, ip: str = None) -> Category:
    cat = db.query(Category).filter(Category.id == cat_id).first()
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    
    before = {
        "name": cat.name,
        "is_active": cat.is_active,
        "sort_order": cat.sort_order,
        "color": cat.color,
        "icon": cat.icon,
        "type": cat.type
    }
    
    update_data = data.model_dump(exclude_unset=True)
    
    # Safety guards for protected categories
    if cat.name in PROTECTED_CATEGORIES:
        if "is_active" in update_data and not update_data["is_active"]:
            raise HTTPException(status_code=400, detail="Cannot deactivate system default categories")
        if "name" in update_data and update_data["name"] != cat.name:
            raise HTTPException(status_code=400, detail="Cannot rename system default categories")
            
    for field, value in update_data.items():
        setattr(cat, field, value)
    db.commit()
    db.refresh(cat)
    _invalidate_caches()
    
    after = {
        "name": cat.name,
        "is_active": cat.is_active,
        "sort_order": cat.sort_order,
        "color": cat.color,
        "icon": cat.icon,
        "type": cat.type
    }
    audit_service.log_change(db, user, "update_category", "category", str(cat.id), before, after, ip)
    return cat


def delete_category(db: Session, cat_id: int, user: User, ip: str = None) -> Category:
    """Soft-delete: sets is_active=False."""
    cat = db.query(Category).filter(Category.id == cat_id).first()
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    if cat.name in PROTECTED_CATEGORIES:
        raise HTTPException(status_code=400, detail="Cannot delete or deactivate system default categories")
        
    before = {"name": cat.name, "is_active": True}
    cat.is_active = False
    db.commit()
    db.refresh(cat)
    _invalidate_caches()
    audit_service.log_change(db, user, "delete_category", "category", str(cat.id), before, {"is_active": False}, ip)
    return cat


def reorder_categories(db: Session, items: list, user: User, ip: str = None):
    for item in items:
        cat = db.query(Category).filter(Category.id == item.get("id")).first()
        if cat:
            cat.sort_order = item.get("sort_order", 0)
    db.commit()
    _invalidate_caches()
    audit_service.log_change(db, user, "reorder_categories", "category", None, None, {"items": items}, ip)
