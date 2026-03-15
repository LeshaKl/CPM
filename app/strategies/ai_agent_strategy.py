from collections import defaultdict, deque

from app.core.config import get_settings
from app.models.enums import DecisionAction
from app.strategies.base import BaseStrategy, MarketState, PortfolioState, StrategyDecision


_SYMBOL_PRICE_HISTORY: dict[str, deque[float]] = defaultdict(lambda: deque(maxlen=40))


class AIAgentStrategy(BaseStrategy):
    name = "ai_agent_strategy"

    def __init__(self) -> None:
        settings = get_settings()
        self.base_order_amount = settings.simple_order_amount

    def decide(self, market_state: MarketState, portfolio_state: PortfolioState) -> StrategyDecision:
        history = _SYMBOL_PRICE_HISTORY[market_state.symbol]
        history.append(market_state.price)

        if len(history) < 6:
            return StrategyDecision(
                action=DecisionAction.HOLD,
                amount=0.0,
                reason="collecting enough price history for agent model",
            )

        short_window = list(history)[-4:]
        long_window = list(history)[-12:]
        short_avg = sum(short_window) / len(short_window)
        long_avg = sum(long_window) / len(long_window)
        momentum = short_window[-1] - short_window[0]
        mean_reversion = (market_state.price - long_avg) / max(long_avg, 0.0001)
        volatility = (max(long_window) - min(long_window)) / max(long_avg, 0.0001)
        cash_ratio = portfolio_state.cash_balance / max(portfolio_state.total_value, 1.0)
        asset_ratio = (portfolio_state.asset_balance * market_state.price) / max(portfolio_state.total_value, 1.0)

        score = 0.0
        score += (short_avg - long_avg) / max(long_avg, 0.0001) * 4.5
        score += momentum / max(long_avg, 0.0001) * 2.8
        score -= mean_reversion * 2.1
        score -= max(volatility - 0.035, 0.0) * 3.0
        score += (cash_ratio - 0.5) * 0.6
        score -= max(asset_ratio - 0.65, 0.0) * 1.4

        order_amount = round(max(self.base_order_amount, self.base_order_amount * (1.0 + abs(score))), 4)

        if score >= 0.18 and portfolio_state.cash_balance >= market_state.price * self.base_order_amount:
            return StrategyDecision(
                action=DecisionAction.BUY,
                amount=order_amount,
                reason=(
                    "agent buy score "
                    f"{score:.3f}: short trend above base, momentum positive, volatility {volatility:.3f}"
                ),
            )

        if score <= -0.18 and portfolio_state.asset_balance > 0:
            return StrategyDecision(
                action=DecisionAction.SELL,
                amount=min(order_amount, portfolio_state.asset_balance),
                reason=(
                    "agent sell score "
                    f"{score:.3f}: momentum fading or price stretched, volatility {volatility:.3f}"
                ),
            )

        return StrategyDecision(
            action=DecisionAction.HOLD,
            amount=0.0,
            reason=f"agent hold score {score:.3f}: no clean edge",
        )
