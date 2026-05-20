"""Stats and analytics router."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.auth import get_current_admin
from app.schemas import SystemStatsResponse
from app.services import stats_service

router = APIRouter(prefix="/api/settings/stats", tags=["stats"])


@router.get("", response_model=SystemStatsResponse)
def get_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin),
):
    """Get system statistics — Admin+ only."""
    return stats_service.get_system_stats(db)
