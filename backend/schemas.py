from datetime import datetime

from pydantic import BaseModel


class BotCreate(BaseModel):
    name: str
    symbol: str
    strategy: str = "sma_crossover"
    initial_capital: float = 10_000.0


class TradeResponse(BaseModel):
    id: int
    bot_id: int
    side: str
    symbol: str
    price: float
    amount: float
    timestamp: datetime

    model_config = {"from_attributes": True}


class MetricResponse(BaseModel):
    id: int
    bot_id: int
    equity: float
    pnl: float
    pnl_percent: float
    sharpe: float
    max_drawdown: float
    win_rate: float
    total_trades: int
    timestamp: datetime

    model_config = {"from_attributes": True}


class DecisionResponse(BaseModel):
    id: int
    bot_id: int
    action: str
    reasoning: str
    confidence: float
    timestamp: datetime

    model_config = {"from_attributes": True}


class BotResponse(BaseModel):
    id: int
    name: str
    symbol: str
    strategy: str
    status: str
    initial_capital: float
    created_at: datetime
    latest_metric: MetricResponse | None = None

    model_config = {"from_attributes": True}


class DashboardResponse(BaseModel):
    total_bots: int
    active_bots: int
    total_equity: float
    total_pnl: float
    avg_sharpe: float
    best_bot_name: str | None
    best_bot_pnl: float
    equity_history: list[dict]


class AnalyzeResponse(BaseModel):
    bot_id: int
    action: str
    reasoning: str
    confidence: float


class BacktestResponse(BaseModel):
    bot_id: int
    trades_count: int
    final_equity: float
    pnl: float
    pnl_percent: float
    sharpe: float
    max_drawdown: float
    win_rate: float
