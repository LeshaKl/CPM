from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.portfolio import PortfolioResponse
from app.services.portfolio_service import get_bot_or_raise, get_portfolio_by_bot_id


router = APIRouter(prefix="/portfolio", tags=["portfolio"])


@router.get("/{bot_id}", response_model=PortfolioResponse)
def get_portfolio(bot_id: int, db: Session = Depends(get_db)) -> PortfolioResponse:
    get_bot_or_raise(db=db, bot_id=bot_id)
    return get_portfolio_by_bot_id(db=db, bot_id=bot_id)
