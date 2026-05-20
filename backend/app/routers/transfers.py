from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.database import get_db
from app.schemas import TransferCreate, TransferResponse, TransferBase
from app.models import Transfer, User, RoleEnum
from app.auth import get_current_user
from app.utils.notification_helper import create_notification

router = APIRouter(prefix="/api/transfers", tags=["transfers"])

@router.get("", response_model=List[TransferResponse])
def get_transfers(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    user_id: Optional[int] = None,
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
        
    return query.order_by(Transfer.date.desc()).all()

@router.post("", response_model=TransferResponse, status_code=status.HTTP_201_CREATED)
async def create_transfer(
    transfer_in: TransferCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_transfer = Transfer(**transfer_in.model_dump(), user_id=current_user.id)
    db.add(new_transfer)
    db.commit()
    db.refresh(new_transfer)
    
    await create_notification(
        db=db,
        title="Transfer Executed",
        message=f"Transfer: {new_transfer.amount_from} {new_transfer.currency_from.value} -> {new_transfer.amount_to} {new_transfer.currency_to.value}",
        type="transfer",
        priority="normal",
        target_user_id=current_user.id
    )
    
    return new_transfer

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
        
    transfer_query.update(transfer_in.model_dump(), synchronize_session=False)
    db.commit()
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
        
    db.delete(transfer)
    db.commit()
