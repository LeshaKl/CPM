import os

from functools import lru_cache
from pydantic import BaseModel


def _env_bool(name: str, default: bool) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


class Settings(BaseModel):
    app_name: str = "AI Trading Bot Paper Trading API"
    api_prefix: str = ""
    database_url: str = "sqlite:///./app.db"
    initial_cash_balance: float = 10_000.0
    simple_buy_threshold: float = 95.0
    simple_sell_threshold: float = 105.0
    simple_order_amount: float = 0.1
    market_data_provider: str = os.getenv("MARKET_DATA_PROVIDER", "mock")
    market_data_api_token: str | None = os.getenv("MARKET_DATA_API_TOKEN")
    default_candle_limit: int = 50
    tbank_api_base_url: str = "https://invest-public-api.tbank.ru/rest"
    tbank_default_class_code: str = os.getenv("TBANK_DEFAULT_CLASS_CODE", "TQBR")
    market_data_timeout_seconds: float = 5.0
    bot_runner_interval_seconds: float = 3.0
    market_data_verify_ssl: bool = _env_bool("MARKET_DATA_VERIFY_SSL", False)


@lru_cache
def get_settings() -> Settings:
    return Settings()
