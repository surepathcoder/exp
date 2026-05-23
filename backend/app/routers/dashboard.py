from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import Dict
from sqlalchemy import func
import time
import urllib.request
import json

from app.database import get_db
from app.models import Expense, User, RoleEnum, Income, Transfer, SystemSettings
from app.auth import get_current_user

router = APIRouter(prefix="/api/dashboard", tags=["dashboard"])

# Simple cache for exchange rates relative to USD
_rates_cache = {
    "timestamp": 0,
    "rates": {"USD": 1.0, "TZS": 2500.0, "KES": 130.0}
}
CACHE_DURATION = 12 * 60 * 60


def _fetch_live_rates() -> Dict[str, float]:
    """Fetch rates from external API."""
    try:
        req = urllib.request.Request(
            "https://open.er-api.com/v6/latest/USD",
            headers={'User-Agent': 'Mozilla/5.0'}
        )
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
            if data.get("result") == "success":
                fetched = data.get("rates", {})
                return {
                    "USD": float(fetched.get("USD", 1.0)),
                    "TZS": float(fetched.get("TZS", 2500.0)),
                    "KES": float(fetched.get("KES", 130.0)),
                }
    except Exception as e:
        print(f"Error fetching live rates: {e}")
    return None


def get_rates_with_settings(db: Session) -> Dict[str, float]:
    """Get rates — respects SystemSettings.use_live_rates toggle."""
    settings = db.query(SystemSettings).filter(SystemSettings.id == 1).first()

    if settings and not settings.use_live_rates:
        manual = settings.manual_rates or {}
        return {
            "USD": 1.0,
            "TZS": float(manual.get("USD_TZS", 2500.0)),
            "KES": float(manual.get("USD_KES", 130.0)),
        }

    current_time = time.time()
    if current_time - _rates_cache["timestamp"] < CACHE_DURATION:
        return _rates_cache["rates"]

    live = _fetch_live_rates()
    if live:
        _rates_cache["rates"] = live
        _rates_cache["timestamp"] = current_time
        return live
    return _rates_cache["rates"]


@router.get("/rates", response_model=Dict[str, float])
def get_rates(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return get_rates_with_settings(db)


@router.get("/balance", response_model=Dict[str, float])
def get_balance(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Incomes
    income_query = db.query(Income.currency, func.sum(Income.amount).label("total"))
    if current_user.role == RoleEnum.user:
        income_query = income_query.filter(Income.user_id == current_user.id)
    income_results = income_query.group_by(Income.currency).all()

    # Expenses
    expense_query = db.query(Expense.currency, func.sum(Expense.amount).label("total"))
    if current_user.role == RoleEnum.user:
        expense_query = expense_query.filter(Expense.user_id == current_user.id)
    expense_results = expense_query.group_by(Expense.currency).all()

    # Transfers Out
    trans_out_query = db.query(Transfer.currency_from, func.sum(Transfer.amount_from).label("total"))
    if current_user.role == RoleEnum.user:
        trans_out_query = trans_out_query.filter(Transfer.user_id == current_user.id)
    trans_out_results = trans_out_query.group_by(Transfer.currency_from).all()

    # Transfers In
    trans_in_query = db.query(Transfer.currency_to, func.sum(Transfer.amount_to).label("total"))
    if current_user.role == RoleEnum.user:
        trans_in_query = trans_in_query.filter(Transfer.user_id == current_user.id)
    trans_in_results = trans_in_query.group_by(Transfer.currency_to).all()

    balances = {"USD": 0.0, "TZS": 0.0, "KES": 0.0}

    for currency, total in income_results:
        if currency and total:
            balances[currency.value] += float(total)
    for currency, total in expense_results:
        if currency and total:
            balances[currency.value] -= float(total)
    for currency, total in trans_out_results:
        if currency and total:
            balances[currency.value] -= float(total)
    for currency, total in trans_in_results:
        if currency and total:
            balances[currency.value] += float(total)
    return balances


@router.get("/self-receipt-percentage")
def get_self_receipt_percentage(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
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
