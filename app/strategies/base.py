from abc import ABC, abstractmethod
from datetime import datetime

from pydantic import BaseModel

from app.models.enums import DecisionAction


class MarketState(BaseModel):
    symbol: str
    price: float
    timestamp: datetime


class PortfolioState(BaseModel):
    cash_balance: float
    asset_balance: float
    total_value: float


class StrategyDecision(BaseModel):
    action: DecisionAction
    amount: float
    reason: str


class BaseStrategy(ABC):
    name: str

    @abstractmethod
    def decide(self, market_state: MarketState, portfolio_state: PortfolioState) -> StrategyDecision:
        raise NotImplementedError
