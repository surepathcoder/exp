from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.database import get_db
from app.schemas import TransferCreate, TransferResponse, TransferBase
from app.models import Transfer, User, RoleEnum, Project, ProjectStatusEnum
from app.models.wallet import Wallet
from app.auth import get_current_user
from app.utils.notification_helper import create_notification
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

router = APIRouter(prefix="/api/transfers", tags=["transfers"])

@router.get("", response_model=List[TransferResponse])
def get_transfers(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    user_id: Optional[int] = None,
    project: Optional[List[str]] = Query(None),
    project_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Transfer)
    
    # Permission check: normal users can only see their own
    if current_user.role == RoleEnum.user:
        query = query.filter(Transfer.user_id == current_user.id)
    else:
        # Admins/Superadmins can filter by user_id
        if user_id is not None:
            query = query.filter(Transfer.user_id == user_id)
            
    if start_date:
        query = query.filter(Transfer.date >= start_date)
    if end_date:
        query = query.filter(Transfer.date <= end_date)
    if project_id is not None:
        query = query.filter(Transfer.project_id == project_id)
    if project:
        query = query.join(Transfer.project_relation).filter(Project.name.in_(project))
        
    return query.order_by(Transfer.date.desc()).offset(skip).limit(limit).all()

@router.post("", response_model=TransferResponse, status_code=status.HTTP_201_CREATED)
async def create_transfer(
    transfer_in: TransferCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    _validate_wallet_currency(db, transfer_in.wallet_from_id, transfer_in.currency_from.value, current_user)
    _validate_wallet_currency(db, transfer_in.wallet_to_id, transfer_in.currency_to.value, current_user)
    
    # Project validation
    if transfer_in.project_id is not None:
        project = db.query(Project).filter(Project.id == transfer_in.project_id).first()
        if not project:
            raise HTTPException(status_code=400, detail="Selected project does not exist")
        if project.status in [ProjectStatusEnum.completed, ProjectStatusEnum.expired, ProjectStatusEnum.cancelled]:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot attach transactions to a project with status '{project.status.value}'"
            )

    transfer_data = transfer_in.model_dump()
    transfer_data.pop("project", None)
    new_transfer = Transfer(**transfer_data, user_id=current_user.id)
    db.add(new_transfer)
    db.commit()
    db.refresh(new_transfer)
    
    if new_transfer.wallet_from_id:
        sync_wallet_balance(db, new_transfer.wallet_from_id)
    if new_transfer.wallet_to_id:
        sync_wallet_balance(db, new_transfer.wallet_to_id)
        
    await create_notification(
        db=db,
        title="Transfer Executed",
        message=f"Transfer: {new_transfer.amount_from} {new_transfer.currency_from.value} -> {new_transfer.amount_to} {new_transfer.currency_to.value}",
        type="transfer",
        priority="normal",
        target_user_id=current_user.id
    )
    
    return new_transfer


@router.get("/{transfer_id}", response_model=TransferResponse)
def get_transfer(
    transfer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    transfer = db.query(Transfer).filter(Transfer.id == transfer_id).first()
    if not transfer:
        raise HTTPException(status_code=404, detail="Transfer not found")
        
    if current_user.role == RoleEnum.user and transfer.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this transfer")
        
    return transfer


@router.put("/{transfer_id}", response_model=TransferResponse)
def update_transfer(
    transfer_id: int,
    transfer_in: TransferBase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    transfer_query = db.query(Transfer).filter(Transfer.id == transfer_id)
    transfer = transfer_query.first()
    
    if not transfer:
        raise HTTPException(status_code=404, detail="Transfer not found")
        
    if current_user.role == RoleEnum.user and transfer.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this transfer")
        
    old_from_id = transfer.wallet_from_id
    old_to_id = transfer.wallet_to_id
    
    _validate_wallet_currency(db, transfer_in.wallet_from_id, transfer_in.currency_from.value, current_user)
    _validate_wallet_currency(db, transfer_in.wallet_to_id, transfer_in.currency_to.value, current_user)
    
    # Project validation
    if transfer_in.project_id is not None:
        project = db.query(Project).filter(Project.id == transfer_in.project_id).first()
        if not project:
            raise HTTPException(status_code=400, detail="Selected project does not exist")
        if project.status in [ProjectStatusEnum.completed, ProjectStatusEnum.expired, ProjectStatusEnum.cancelled]:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot attach transactions to a project with status '{project.status.value}'"
            )

    transfer_data = transfer_in.model_dump()
    transfer_data.pop("project", None)
    transfer_query.update(transfer_data, synchronize_session=False)
    db.commit()
    
    # Sync new wallets
    if transfer_in.wallet_from_id:
        sync_wallet_balance(db, transfer_in.wallet_from_id)
    if transfer_in.wallet_to_id:
        sync_wallet_balance(db, transfer_in.wallet_to_id)
        
    # Sync old wallets if changed
    if old_from_id and old_from_id != transfer_in.wallet_from_id:
        sync_wallet_balance(db, old_from_id)
    if old_to_id and old_to_id != transfer_in.wallet_to_id:
        sync_wallet_balance(db, old_to_id)
        
    return transfer_query.first()

@router.delete("/{transfer_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transfer(
    transfer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    transfer = db.query(Transfer).filter(Transfer.id == transfer_id).first()
    
    if not transfer:
        raise HTTPException(status_code=404, detail="Transfer not found")
        
    if current_user.role == RoleEnum.user and transfer.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this transfer")
        
    from_id = transfer.wallet_from_id
    to_id = transfer.wallet_to_id
    
    db.delete(transfer)
    db.commit()
    
    if from_id:
        sync_wallet_balance(db, from_id)
    if to_id:
        sync_wallet_balance(db, to_id)
