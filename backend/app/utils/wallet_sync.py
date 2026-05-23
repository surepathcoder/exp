from sqlalchemy.orm import Session
from sqlalchemy import func
from decimal import Decimal
from app.models.wallet import Wallet
from app.models.core import Expense, Income, Transfer

def sync_wallet_balance(db: Session, wallet_id: int):
    """Recalculate wallet balance by summing all transactions and adding the opening balance."""
    wallet = db.query(Wallet).filter(Wallet.id == wallet_id).first()
    if not wallet:
        return

    # Total Incomes into this wallet
    incomes_sum = db.query(func.coalesce(func.sum(Income.amount), Decimal('0.00')))\
                    .filter(Income.wallet_id == wallet_id).scalar()

    # Total Expenses from this wallet
    expenses_sum = db.query(func.coalesce(func.sum(Expense.amount), Decimal('0.00')))\
                     .filter(Expense.wallet_id == wallet_id).scalar()

    # Total Transfers Out of this wallet
    transfers_out_sum = db.query(func.coalesce(func.sum(Transfer.amount_from), Decimal('0.00')))\
                          .filter(Transfer.wallet_from_id == wallet_id).scalar()

    # Total Transfers Into this wallet
    transfers_in_sum = db.query(func.coalesce(func.sum(Transfer.amount_to), Decimal('0.00')))\
                         .filter(Transfer.wallet_to_id == wallet_id).scalar()

    # Calculated Balance
    wallet.balance = (
        Decimal(str(wallet.opening_balance)) +
        Decimal(str(incomes_sum)) -
        Decimal(str(expenses_sum)) -
        Decimal(str(transfers_out_sum)) +
        Decimal(str(transfers_in_sum))
    )
    db.commit()
