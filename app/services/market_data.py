from abc import ABC, abstractmethod
from collections import defaultdict, deque
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from functools import lru_cache
import json
import math
import ssl
from urllib import error, request

from app.core.config import get_settings
from app.schemas.market_data import (
    CandleResponse,
    InstrumentSearchItem,
    InstrumentSearchResponse,
    MarketCandlesResponse,
    MarketFeedStatusResponse,
    MarketSnapshotResponse,
)
from app.strategies.base import MarketState


_SUPPORTED_INTERVALS = {"1m": 1, "5m": 5, "15m": 15, "1h": 60, "1d": 1440}
_TBANK_INTERVAL_MAP = {
    "1m": "CANDLE_INTERVAL_1_MIN",
    "5m": "CANDLE_INTERVAL_5_MIN",
    "15m": "CANDLE_INTERVAL_15_MIN",
    "1h": "CANDLE_INTERVAL_HOUR",
    "1d": "CANDLE_INTERVAL_DAY",
}
_MAX_SIMULATED_CANDLES = 720


@dataclass
class SimulatedTick:
    timestamp: datetime
    open: float
    high: float
    low: float
    close: float
    volume: float


_SIMULATED_SERIES: dict[str, deque[SimulatedTick]] = defaultdict(lambda: deque(maxlen=_MAX_SIMULATED_CANDLES))


@dataclass(frozen=True)
class MarketFeedInfo:
    provider: str
    effective_mode: str
    token_configured: bool
    notes: list[str]


class BaseMarketDataProvider(ABC):
    feed_info: MarketFeedInfo

    @abstractmethod
    def get_market_state(self, symbol: str) -> MarketState:
        raise NotImplementedError

    @abstractmethod
    def get_candles(self, symbol: str, limit: int, interval: str) -> list[CandleResponse]:
        raise NotImplementedError

    @abstractmethod
    def normalize_symbol(self, symbol: str) -> str:
        raise NotImplementedError

    @abstractmethod
    def search_instruments(self, query: str, limit: int) -> list[InstrumentSearchItem]:
        raise NotImplementedError

    def probe_connection(self) -> None:
        return None


class MockMarketDataProvider(BaseMarketDataProvider):
    def __init__(self) -> None:
        settings = get_settings()
        requested_provider = settings.market_data_provider
        token_configured = bool(settings.market_data_api_token)
        effective_mode = "mock"
        notes = ["Using generated mock market data."]
        if requested_provider != "mock" and token_configured:
            effective_mode = "mock_fallback"
            notes.append("A real market data token is configured, but provider fallback is active.")

        self.feed_info = MarketFeedInfo(
            provider=requested_provider,
            effective_mode=effective_mode,
            token_configured=token_configured,
            notes=notes,
        )

    def get_market_state(self, symbol: str) -> MarketState:
        self._advance_symbol(symbol)
        latest_tick = _SIMULATED_SERIES[symbol][-1]
        return MarketState(
            symbol=symbol,
            price=latest_tick.close,
            timestamp=latest_tick.timestamp,
        )

    def get_candles(self, symbol: str, limit: int, interval: str) -> list[CandleResponse]:
        if interval not in _SUPPORTED_INTERVALS:
            supported = ", ".join(sorted(_SUPPORTED_INTERVALS))
            raise ValueError(f"Unsupported interval '{interval}'. Supported intervals: {supported}")
        self._ensure_history(symbol=symbol, min_points=max(limit * _SUPPORTED_INTERVALS[interval], 160))
        return self._compress_ticks(
            ticks=list(_SIMULATED_SERIES[symbol]),
            step_size=_SUPPORTED_INTERVALS[interval],
            limit=limit,
        )

    def normalize_symbol(self, symbol: str) -> str:
        return symbol

    def search_instruments(self, query: str, limit: int) -> list[InstrumentSearchItem]:
        candidates = [
            ("SBER", "TQBR", "Sberbank", "share"),
            ("GAZP", "TQBR", "Gazprom", "share"),
            ("LKOH", "TQBR", "Lukoil", "share"),
            ("YDEX", "TQBR", "Yandex", "share"),
            ("ROSN", "TQBR", "Rosneft", "share"),
            ("MGNT", "TQBR", "Magnit", "share"),
        ]
        query_upper = query.strip().upper()
        items = [
            InstrumentSearchItem(
                ticker=ticker,
                class_code=class_code,
                name=name,
                instrument_type=instrument_type,
                exchange="MOEX",
            )
            for ticker, class_code, name, instrument_type in candidates
            if query_upper in ticker or query_upper in name.upper()
        ]
        return items[:limit]

    def _ensure_history(self, symbol: str, min_points: int) -> None:
        target = min(min_points, _MAX_SIMULATED_CANDLES)
        while len(_SIMULATED_SERIES[symbol]) < target:
            self._advance_symbol(symbol)

    def _advance_symbol(self, symbol: str) -> None:
        series = _SIMULATED_SERIES[symbol]
        now = datetime.now(timezone.utc)
        index = len(series)
        previous_close = series[-1].close if series else 96 + (sum(map(ord, symbol)) % 11)
        seed = sum(ord(char) for char in symbol)

        trend = math.sin((index + seed) / 7.5) * 1.45
        wave = math.cos((index + seed) / 3.1) * 0.85
        drift = math.sin((index + seed) / 24.0) * 0.35
        close_price = max(1.0, previous_close + trend * 0.34 + wave * 0.22 + drift)
        open_price = previous_close
        high_price = max(open_price, close_price) + 0.22 + abs(wave) * 0.26
        low_price = min(open_price, close_price) - 0.19 - abs(trend) * 0.18
        volume = 130 + (index % 17) * 11 + abs(trend) * 35

        series.append(
            SimulatedTick(
                timestamp=now if not series else max(now, series[-1].timestamp + timedelta(seconds=3)),
                open=round(open_price, 2),
                high=round(high_price, 2),
                low=round(max(0.1, low_price), 2),
                close=round(close_price, 2),
                volume=round(volume, 2),
            )
        )

    def _compress_ticks(
        self,
        ticks: list[SimulatedTick],
        step_size: int,
        limit: int,
    ) -> list[CandleResponse]:
        if step_size <= 1:
            selected = ticks[-limit:]
            return [
                CandleResponse(
                    timestamp=tick.timestamp,
                    open=tick.open,
                    high=tick.high,
                    low=tick.low,
                    close=tick.close,
                    volume=tick.volume,
                )
                for tick in selected
            ]

        aggregated: list[CandleResponse] = []
        for index in range(0, len(ticks), step_size):
            chunk = ticks[index : index + step_size]
            if not chunk:
                continue
            aggregated.append(
                CandleResponse(
                    timestamp=chunk[-1].timestamp,
                    open=chunk[0].open,
                    high=max(item.high for item in chunk),
                    low=min(item.low for item in chunk),
                    close=chunk[-1].close,
                    volume=round(sum(item.volume for item in chunk), 2),
                )
            )
        return aggregated[-limit:]


class TBankMarketDataProvider(BaseMarketDataProvider):
    def __init__(self) -> None:
        settings = get_settings()
        if not settings.market_data_api_token:
            raise ValueError("MARKET_DATA_API_TOKEN is required for provider 'tbank'")

        self.token = settings.market_data_api_token
        self.base_url = settings.tbank_api_base_url.rstrip("/")
        self.timeout_seconds = settings.market_data_timeout_seconds
        self.default_class_code = settings.tbank_default_class_code
        self.verify_ssl = settings.market_data_verify_ssl
        self.feed_info = MarketFeedInfo(
            provider="tbank",
            effective_mode="live_market_data",
            token_configured=True,
            notes=[
                "Read-only market data from T-Invest API.",
                "Paper trading execution remains local and simulated.",
                "Ticker search resolves different shares dynamically through InstrumentsService.",
                "When live mode is active, chart candles and bot decisions use exchange data from T-Bank.",
            ],
        )

    def normalize_symbol(self, symbol: str) -> str:
        cleaned = symbol.strip().upper()
        if "_" in cleaned:
            return cleaned
        instrument = self._resolve_symbol(cleaned)
        return f"{instrument.ticker}_{instrument.class_code}"

    def search_instruments(self, query: str, limit: int) -> list[InstrumentSearchItem]:
        payload = {
            "query": query.strip().upper(),
            "instrumentKind": "INSTRUMENT_TYPE_SHARE",
            "apiTradeAvailableFlag": True,
        }
        data = self._post(
            "tinkoff.public.invest.api.contract.v1.InstrumentsService/FindInstrument",
            payload,
        )
        instruments = data.get("instruments", [])
        items: list[InstrumentSearchItem] = []
        for item in instruments:
            ticker = str(item.get("ticker", "")).upper()
            class_code = str(item.get("classCode", "")).upper()
            if not ticker or not class_code:
                continue
            items.append(
                InstrumentSearchItem(
                    ticker=ticker,
                    class_code=class_code,
                    name=str(item.get("name", ticker)),
                    instrument_type=str(item.get("instrumentKind", "share")).lower(),
                    exchange=item.get("exchange"),
                    uid=item.get("uid"),
                )
            )

        query_upper = query.strip().upper()
        items.sort(
            key=lambda item: (
                0 if item.ticker == query_upper else 1,
                0 if item.class_code == self.default_class_code else 1,
                item.ticker,
            )
        )
        return items[:limit]

    @lru_cache(maxsize=256)
    def _resolve_symbol(self, symbol: str) -> InstrumentSearchItem:
        matches = self.search_instruments(symbol, limit=12)
        exact = [item for item in matches if item.ticker == symbol]
        if exact:
            preferred = next(
                (item for item in exact if item.class_code == self.default_class_code),
                exact[0],
            )
            return preferred
        if matches:
            return matches[0]
        raise ValueError(f"T-Bank did not find a share instrument for ticker '{symbol}'")

    def probe_connection(self) -> None:
        self.search_instruments("SBER", limit=1)

    def get_market_state(self, symbol: str) -> MarketState:
        instrument_id = self.normalize_symbol(symbol)
        payload = {
            "instrumentId": [instrument_id],
            "lastPriceType": "LAST_PRICE_EXCHANGE",
            "instrumentStatus": "INSTRUMENT_STATUS_BASE",
        }
        data = self._post(
            "tinkoff.public.invest.api.contract.v1.MarketDataService/GetLastPrices",
            payload,
        )
        last_prices = data.get("lastPrices", [])
        if not last_prices:
            raise ValueError(f"T-Bank did not return last price for symbol '{instrument_id}'")

        item = last_prices[0]
        price = _quotation_to_float(item["price"])
        timestamp_raw = item.get("time")
        timestamp = _parse_tbank_datetime(timestamp_raw)
        return MarketState(symbol=symbol, price=price, timestamp=timestamp)

    def get_candles(self, symbol: str, limit: int, interval: str) -> list[CandleResponse]:
        if interval not in _TBANK_INTERVAL_MAP:
            supported = ", ".join(sorted(_TBANK_INTERVAL_MAP))
            raise ValueError(f"Unsupported interval '{interval}'. Supported intervals: {supported}")

        instrument_id = self.normalize_symbol(symbol)
        now = datetime.now(timezone.utc)
        step_minutes = _SUPPORTED_INTERVALS[interval]
        period_start = now - timedelta(minutes=step_minutes * limit)
        payload = {
            "instrumentId": instrument_id,
            "from": period_start.isoformat(),
            "to": now.isoformat(),
            "interval": _TBANK_INTERVAL_MAP[interval],
        }
        data = self._post(
            "tinkoff.public.invest.api.contract.v1.MarketDataService/GetCandles",
            payload,
        )
        candles_raw = data.get("candles", [])
        candles: list[CandleResponse] = []
        for candle in candles_raw:
            candles.append(
                CandleResponse(
                    timestamp=_parse_tbank_datetime(candle["time"]),
                    open=_quotation_to_float(candle["open"]),
                    high=_quotation_to_float(candle["high"]),
                    low=_quotation_to_float(candle["low"]),
                    close=_quotation_to_float(candle["close"]),
                    volume=float(candle.get("volume", 0.0)),
                )
            )
        return candles[-limit:]

    def _post(self, path: str, payload: dict[str, object]) -> dict[str, object]:
        body = json.dumps(payload).encode("utf-8")
        url = f"{self.base_url}/{path}"
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
        req = request.Request(url=url, data=body, headers=headers, method="POST")
        try:
            with request.urlopen(
                req,
                timeout=self.timeout_seconds,
                context=_build_ssl_context(self.verify_ssl),
            ) as response:
                return json.loads(response.read().decode("utf-8"))
        except error.HTTPError as exc:
            details = exc.read().decode("utf-8", errors="ignore")
            raise ValueError(f"T-Bank API error {exc.code}: {details or exc.reason}") from exc
        except error.URLError as exc:
            raise ValueError(f"T-Bank API connection failed: {exc.reason}") from exc


def _get_provider() -> BaseMarketDataProvider:
    settings = get_settings()
    if settings.market_data_provider == "tbank":
        return TBankMarketDataProvider()
    return MockMarketDataProvider()


def _get_provider_with_fallback() -> tuple[BaseMarketDataProvider, BaseMarketDataProvider | None]:
    try:
        provider = _get_provider()
        return provider, None
    except ValueError:
        fallback = MockMarketDataProvider()
        return fallback, fallback


def _build_ssl_context(verify_ssl: bool) -> ssl.SSLContext:
    if verify_ssl:
        return ssl.create_default_context()
    return ssl._create_unverified_context()


def _is_live_requested() -> bool:
    return get_settings().market_data_provider == "tbank"


def _quotation_to_float(value: dict[str, object]) -> float:
    units = int(value.get("units", 0))
    nano = int(value.get("nano", 0))
    return units + nano / 1_000_000_000


def _parse_tbank_datetime(raw_value: str | None) -> datetime:
    if not raw_value:
        return datetime.now(timezone.utc)
    normalized = raw_value.replace("Z", "+00:00")
    return datetime.fromisoformat(normalized)


def get_market_feed_status() -> MarketFeedStatusResponse:
    provider, fallback = _get_provider_with_fallback()
    notes = list(provider.feed_info.notes)
    if fallback is not None:
        notes.append("Fell back to mock provider because real provider initialization failed.")
    elif isinstance(provider, TBankMarketDataProvider):
        try:
            provider.probe_connection()
            notes.append("Live connection check passed.")
        except ValueError as exc:
            notes.append(f"Live connection check failed: {exc}")
    return MarketFeedStatusResponse(
        provider=provider.feed_info.provider,
        effective_mode=provider.feed_info.effective_mode,
        token_configured=provider.feed_info.token_configured,
        notes=notes,
    )


def search_instruments(query: str, limit: int = 10) -> InstrumentSearchResponse:
    provider, fallback = _get_provider_with_fallback()
    try:
        items = provider.search_instruments(query=query, limit=limit)
    except ValueError:
        if _is_live_requested():
            raise
        if fallback is None:
            raise
        items = fallback.search_instruments(query=query, limit=limit)
    return InstrumentSearchResponse(
        query=query,
        provider=provider.feed_info.provider,
        items=items,
    )


def get_market_state(symbol: str) -> MarketState:
    provider, _ = _get_provider_with_fallback()
    try:
        return provider.get_market_state(symbol=symbol)
    except ValueError:
        if _is_live_requested():
            raise
        return MockMarketDataProvider().get_market_state(symbol=symbol)


def get_market_snapshot(symbol: str) -> MarketSnapshotResponse:
    provider, _ = _get_provider_with_fallback()
    source_symbol = symbol
    try:
        source_symbol = provider.normalize_symbol(symbol)
        state = provider.get_market_state(symbol=symbol)
        effective_mode = provider.feed_info.effective_mode
        provider_name = provider.feed_info.provider
    except ValueError:
        if _is_live_requested():
            raise
        fallback = MockMarketDataProvider()
        state = fallback.get_market_state(symbol=symbol)
        effective_mode = "mock_fallback"
        provider_name = provider.feed_info.provider

    return MarketSnapshotResponse(
        symbol=state.symbol,
        price=state.price,
        timestamp=state.timestamp,
        provider=provider_name,
        effective_mode=effective_mode,
        source_symbol=source_symbol,
    )


def get_market_candles(symbol: str, limit: int, interval: str) -> MarketCandlesResponse:
    provider, _ = _get_provider_with_fallback()
    source_symbol = symbol
    try:
        source_symbol = provider.normalize_symbol(symbol)
        candles = provider.get_candles(symbol=symbol, limit=limit, interval=interval)
        effective_mode = provider.feed_info.effective_mode
        provider_name = provider.feed_info.provider
    except ValueError:
        if _is_live_requested():
            raise
        fallback = MockMarketDataProvider()
        candles = fallback.get_candles(symbol=symbol, limit=limit, interval=interval)
        effective_mode = "mock_fallback"
        provider_name = provider.feed_info.provider

    return MarketCandlesResponse(
        symbol=symbol,
        interval=interval,
        provider=provider_name,
        effective_mode=effective_mode,
        source_symbol=source_symbol,
        candles=candles,
    )
