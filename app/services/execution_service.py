from sqlalchemy.orm import Session

from app.core.exceptions import InsufficientAssetBalanceError, InsufficientFundsError
from app.models.bot import Bot
from app.models.decision_log import DecisionLog
from app.models.enums import DecisionAction, TradeSide
from app.models.portfolio import Portfolio
from app.models.trade import Trade
from app.services.portfolio_service import recalculate_total_value
from app.strategies.base import MarketState, StrategyDecision


def execute_decision(
    db: Session,
    bot: Bot,
    portfolio: Portfolio,
    market_state: MarketState,
    decision: StrategyDecision,
) -> DecisionLog:
    if decision.action == DecisionAction.BUY:
        _execute_buy(db=db, bot=bot, portfolio=portfolio, price=market_state.price, amount=decision.amount)
    elif decision.action == DecisionAction.SELL:
        _execute_sell(db=db, bot=bot, portfolio=portfolio, price=market_state.price, amount=decision.amount)

    recalculate_total_value(portfolio=portfolio, current_price=market_state.price)
    decision_log = DecisionLog(
        bot_id=bot.id,
        action=decision.action,
        reason=decision.reason,
        price_snapshot=market_state.price,
    )
    db.add(decision_log)
    db.flush()
    return decision_log


def _execute_buy(db: Session, bot: Bot, portfolio: Portfolio, price: float, amount: float) -> None:
    total_cost = price * amount
    if portfolio.cash_balance < total_cost:
        raise InsufficientFundsError("Not enough cash balance to execute buy order")

    portfolio.cash_balance -= total_cost
    portfolio.asset_balance += amount
    trade = Trade(
        bot_id=bot.id,
        symbol=bot.symbol,
        side=TradeSide.BUY,
        price=price,
        amount=amount,
    )
    db.add(trade)
    db.flush()


def _execute_sell(db: Session, bot: Bot, portfolio: Portfolio, price: float, amount: float) -> None:
    if portfolio.asset_balance < amount:
        raise InsufficientAssetBalanceError("Not enough asset balance to execute sell order")

    portfolio.asset_balance -= amount
    portfolio.cash_balance += price * amount
    trade = Trade(
        bot_id=bot.id,
        symbol=bot.symbol,
        side=TradeSide.SELL,
        price=price,
        amount=amount,
    )
    db.add(trade)
    db.flush()
