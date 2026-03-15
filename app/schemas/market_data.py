from datetime import datetime

from pydantic import BaseModel


class MarketFeedStatusResponse(BaseModel):
    provider: str
    effective_mode: str
    token_configured: bool
    live_trading_enabled: bool = False
    notes: list[str] = []


class MarketSnapshotResponse(BaseModel):
    symbol: str
    price: float
    timestamp: datetime
    provider: str
    effective_mode: str
    source_symbol: str


class CandleResponse(BaseModel):
    timestamp: datetime
    open: float
    high: float
    low: float
    close: float
    volume: float


class MarketCandlesResponse(BaseModel):
    symbol: str
    interval: str
    provider: str
    effective_mode: str
    source_symbol: str
    candles: list[CandleResponse]


class InstrumentSearchItem(BaseModel):
    ticker: str
    class_code: str
    name: str
    instrument_type: str
    exchange: str | None = None
    uid: str | None = None


class InstrumentSearchResponse(BaseModel):
    query: str
    provider: str
    items: list[InstrumentSearchItem]
