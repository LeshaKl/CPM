from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.exceptions import BotNotFoundError
from app.models.bot import Bot
from app.models.portfolio import Portfolio


def create_portfolio_for_bot(db: Session, bot_id: int) -> Portfolio:
    settings = get_settings()
    portfolio = Portfolio(
        bot_id=bot_id,
        cash_balance=settings.initial_cash_balance,
        asset_balance=0.0,
        total_value=settings.initial_cash_balance,
    )
    db.add(portfolio)
    db.flush()
    return portfolio


def get_portfolio_by_bot_id(db: Session, bot_id: int) -> Portfolio:
    portfolio = db.scalar(select(Portfolio).where(Portfolio.bot_id == bot_id))
    if portfolio is None:
        raise BotNotFoundError(f"Portfolio for bot {bot_id} was not found")
    return portfolio


def recalculate_total_value(portfolio: Portfolio, current_price: float) -> Portfolio:
    portfolio.total_value = portfolio.cash_balance + portfolio.asset_balance * current_price
    return portfolio


def get_bot_or_raise(db: Session, bot_id: int) -> Bot:
    bot = db.scalar(select(Bot).where(Bot.id == bot_id))
    if bot is None:
        raise BotNotFoundError(f"Bot {bot_id} was not found")
    return bot
