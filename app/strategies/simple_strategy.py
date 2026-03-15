from app.core.config import get_settings
from app.models.enums import DecisionAction
from app.strategies.base import BaseStrategy, MarketState, PortfolioState, StrategyDecision


class SimpleStrategy(BaseStrategy):
    name = "simple_strategy"

    def __init__(self) -> None:
        settings = get_settings()
        self.buy_threshold = settings.simple_buy_threshold
        self.sell_threshold = settings.simple_sell_threshold
        self.order_amount = settings.simple_order_amount

    def decide(self, market_state: MarketState, portfolio_state: PortfolioState) -> StrategyDecision:
        if market_state.price < self.buy_threshold:
            return StrategyDecision(
                action=DecisionAction.BUY,
                amount=self.order_amount,
                reason="price dropped below threshold",
            )

        if market_state.price > self.sell_threshold and portfolio_state.asset_balance > 0:
            sell_amount = min(self.order_amount, portfolio_state.asset_balance)
            return StrategyDecision(
                action=DecisionAction.SELL,
                amount=sell_amount,
                reason="price rose above threshold",
            )

        return StrategyDecision(
            action=DecisionAction.HOLD,
            amount=0.0,
            reason="price within hold range",
        )
