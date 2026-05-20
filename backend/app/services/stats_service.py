"""System stats service — read-only analytics with caching."""
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models import User, Expense, Income, Transfer, Category
from app.services.cache_service import cache

CACHE_KEY = "system_stats"
CACHE_TTL = 120  # 2 minutes


def get_system_stats(db: Session) -> dict:
    cached = cache.get(CACHE_KEY)
    if cached:
        return cached

    total_users = db.query(User).count()
    total_expenses = db.query(Expense).count()
    total_incomes = db.query(Income).count()
    total_transfers = db.query(Transfer).count()
    total_categories = db.query(Category).count()
    active_categories = db.query(Category).filter(Category.is_active == True).count()

    # Total amounts (USD only for simplicity)
    expense_sum = db.query(func.sum(Expense.amount)).filter(
        Expense.currency == "USD"
    ).scalar() or 0.0
    income_sum = db.query(func.sum(Income.amount)).filter(
        Income.currency == "USD"
    ).scalar() or 0.0

    stats = {
        "total_users": total_users,
        "total_expenses": total_expenses,
        "total_incomes": total_incomes,
        "total_transfers": total_transfers,
        "total_categories": total_categories,
        "active_categories": active_categories,
        "total_expense_amount_usd": round(float(expense_sum), 2),
        "total_income_amount_usd": round(float(income_sum), 2),
    }
    cache.set(CACHE_KEY, stats, CACHE_TTL)
    return stats
