from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.bot import Bot
from app.models.enums import BotStatus
from app.models.trade import Trade
from app.models.decision_log import DecisionLog
from app.schemas.bot import BotCreate, BotResponse, BotStatusResponse
from app.schemas.decision_log import DecisionLogResponse
from app.schemas.trade import TradeResponse
from app.services.portfolio_service import create_portfolio_for_bot, get_bot_or_raise
from app.services.trading_engine import run_bot_tick


router = APIRouter(prefix="/bots", tags=["bots"])


@router.post("/create", response_model=BotResponse, status_code=status.HTTP_201_CREATED)
def create_bot(payload: BotCreate, db: Session = Depends(get_db)) -> Bot:
    bot = Bot(
        name=payload.name,
        symbol=payload.symbol,
        strategy_name=payload.strategy_name,
        status=BotStatus.CREATED,
    )
    db.add(bot)
    db.flush()
    create_portfolio_for_bot(db=db, bot_id=bot.id)
    db.commit()
    db.refresh(bot)
    return bot


@router.get("", response_model=list[BotResponse])
def list_bots(db: Session = Depends(get_db)) -> list[Bot]:
    return list(db.scalars(select(Bot).order_by(Bot.id.asc())).all())


@router.get("/{bot_id}", response_model=BotResponse)
def get_bot(bot_id: int, db: Session = Depends(get_db)) -> Bot:
    return get_bot_or_raise(db=db, bot_id=bot_id)


@router.post("/{bot_id}/start", response_model=BotStatusResponse)
def start_bot(bot_id: int, db: Session = Depends(get_db)) -> Bot:
    bot = get_bot_or_raise(db=db, bot_id=bot_id)
    bot.status = BotStatus.RUNNING
    db.commit()
    db.refresh(bot)
    return bot


@router.post("/{bot_id}/stop", response_model=BotStatusResponse)
def stop_bot(bot_id: int, db: Session = Depends(get_db)) -> Bot:
    bot = get_bot_or_raise(db=db, bot_id=bot_id)
    bot.status = BotStatus.STOPPED
    db.commit()
    db.refresh(bot)
    return bot


@router.post("/{bot_id}/tick", response_model=DecisionLogResponse)
def tick_bot(bot_id: int, db: Session = Depends(get_db)) -> DecisionLog:
    return run_bot_tick(db=db, bot_id=bot_id)


@router.get("/{bot_id}/trades", response_model=list[TradeResponse])
def list_bot_trades(bot_id: int, db: Session = Depends(get_db)) -> list[Trade]:
    get_bot_or_raise(db=db, bot_id=bot_id)
    return list(
        db.scalars(
            select(Trade).where(Trade.bot_id == bot_id).order_by(Trade.created_at.desc())
        ).all()
    )


@router.get("/{bot_id}/decisions", response_model=list[DecisionLogResponse])
def list_bot_decisions(bot_id: int, db: Session = Depends(get_db)) -> list[DecisionLog]:
    get_bot_or_raise(db=db, bot_id=bot_id)
    return list(
        db.scalars(
            select(DecisionLog)
            .where(DecisionLog.bot_id == bot_id)
            .order_by(DecisionLog.created_at.desc())
        ).all()
    )
