from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Optional
from decimal import Decimal

from app.database import get_db
from app.models.wallet import Wallet, WalletTypeEnum
from app.models.core import User, RoleEnum, CurrencyEnum, Expense, Income, Transfer
from app.schemas.wallet_schemas import WalletCreate, WalletUpdate, WalletResponse
from app.auth import get_current_user

router = APIRouter(prefix="/api/wallets", tags=["wallets"])

def _seed_default_wallets(db: Session, user_id: int) -> List[Wallet]:
    """Helper to auto-seed default cash wallets for a user."""
    defaults = [
        ("Cash Wallet (USD)", CurrencyEnum.USD, "#3D1B5B", "wallet_travel"),
        ("Cash Wallet (TZS)", CurrencyEnum.TZS, "#FF5200", "payments"),
        ("Cash Wallet (KES)", CurrencyEnum.KES, "#10B981", "account_balance_wallet")
    ]
    wallets = []
    for name, currency, color, icon in defaults:
        w = Wallet(
            name=name,
            type=WalletTypeEnum.cash,
            currency=currency,
            opening_balance=Decimal('0.00'),
            balance=Decimal('0.00'),
            color=color,
            icon=icon,
            is_active=True,
            user_id=user_id
        )
        db.add(w)
        wallets.append(w)
    db.commit()
    for w in wallets:
        db.refresh(w)
    return wallets

@router.get("", response_model=List[WalletResponse])
def get_wallets(
    user_id: Optional[int] = None,
    include_archived: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    target_user_id = current_user.id
    if current_user.role != RoleEnum.user and user_id is not None:
        target_user_id = user_id
        
    query = db.query(Wallet).filter(Wallet.user_id == target_user_id)
    if not include_archived:
        query = query.filter(Wallet.is_active == True)
        
    wallets = query.all()
    if not wallets and target_user_id == current_user.id:
        # Seeding wallets for current user if they have none
        wallets = _seed_default_wallets(db, target_user_id)
        
    return wallets

@router.post("", response_model=WalletResponse, status_code=status.HTTP_201_CREATED)
def create_wallet(
    wallet_in: WalletCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Enforce balance = opening_balance upon creation
    new_wallet = Wallet(
        **wallet_in.model_dump(),
        balance=wallet_in.opening_balance,
        user_id=current_user.id
    )
    db.add(new_wallet)
    db.commit()
    db.refresh(new_wallet)
    return new_wallet

@router.put("/{wallet_id}", response_model=WalletResponse)
def update_wallet(
    wallet_id: int,
    wallet_in: WalletUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    wallet = db.query(Wallet).filter(Wallet.id == wallet_id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")
        
    if current_user.role == RoleEnum.user and wallet.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to edit this wallet")
        
    update_data = wallet_in.model_dump(exclude_unset=True)
    for key, val in update_data.items():
        setattr(wallet, key, val)
        
    db.commit()
    db.refresh(wallet)
    return wallet

@router.delete("/{wallet_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_wallet(
    wallet_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    wallet = db.query(Wallet).filter(Wallet.id == wallet_id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")
        
    if current_user.role == RoleEnum.user and wallet.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this wallet")
        
    # Check if the wallet has any transaction history
    has_expenses = db.query(Expense).filter(Expense.wallet_id == wallet_id).first() is not None
    has_incomes = db.query(Income).filter(Income.wallet_id == wallet_id).first() is not None
    has_transfers = db.query(Transfer).filter(
        or_(Transfer.wallet_from_id == wallet_id, Transfer.wallet_to_id == wallet_id)
    ).first() is not None
    
    if has_expenses or has_incomes or has_transfers:
        # Archive (soft-delete) instead
        wallet.is_active = False
        db.commit()
    else:
        # Hard-delete safe since no records exist
        db.delete(wallet)
        db.commit()
