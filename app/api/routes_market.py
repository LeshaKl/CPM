from fastapi import APIRouter, Query

from app.schemas.market_data import (
    InstrumentSearchResponse,
    MarketCandlesResponse,
    MarketFeedStatusResponse,
    MarketSnapshotResponse,
)
from app.services.market_data import (
    search_instruments,
    get_market_candles,
    get_market_feed_status,
    get_market_snapshot,
)


router = APIRouter(prefix="/market", tags=["market"])


@router.get("/status", response_model=MarketFeedStatusResponse)
def market_status() -> MarketFeedStatusResponse:
    return get_market_feed_status()


@router.get("/instruments/search", response_model=InstrumentSearchResponse)
def instrument_search(
    q: str = Query(min_length=1, max_length=50),
    limit: int = Query(default=10, ge=1, le=30),
) -> InstrumentSearchResponse:
    return search_instruments(query=q, limit=limit)


@router.get("/{symbol}/snapshot", response_model=MarketSnapshotResponse)
def market_snapshot(symbol: str) -> MarketSnapshotResponse:
    return get_market_snapshot(symbol=symbol)


@router.get("/{symbol}/candles", response_model=MarketCandlesResponse)
def market_candles(
    symbol: str,
    limit: int = Query(default=50, ge=10, le=500),
    interval: str = Query(default="1m"),
) -> MarketCandlesResponse:
    return get_market_candles(symbol=symbol, limit=limit, interval=interval)
