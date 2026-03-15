from app.models.decision_log import DecisionLog
from sqlalchemy.orm import Session

from app.core.exceptions import BotNotRunningError
from app.models.enums import BotStatus
from app.services.execution_service import execute_decision
from app.services.market_data import get_market_state
from app.services.portfolio_service import get_bot_or_raise, get_portfolio_by_bot_id
from app.services.strategy_service import get_strategy
from app.strategies.base import PortfolioState


def run_bot_tick(db: Session, bot_id: int) -> DecisionLog:
    bot = get_bot_or_raise(db=db, bot_id=bot_id)
    if bot.status != BotStatus.RUNNING:
        raise BotNotRunningError(f"Bot {bot_id} is not running")

    market_state = get_market_state(bot.symbol)
    portfolio = get_portfolio_by_bot_id(db=db, bot_id=bot.id)
    portfolio_state = PortfolioState(
        cash_balance=portfolio.cash_balance,
        asset_balance=portfolio.asset_balance,
        total_value=portfolio.total_value,
    )
    strategy = get_strategy(bot.strategy_name)
    decision = strategy.decide(market_state=market_state, portfolio_state=portfolio_state)
    decision_log = execute_decision(
        db=db,
        bot=bot,
        portfolio=portfolio,
        market_state=market_state,
        decision=decision,
    )
    db.commit()
    db.refresh(portfolio)
    db.refresh(decision_log)
    return decision_log
