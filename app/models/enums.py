from enum import StrEnum


class BotStatus(StrEnum):
    CREATED = "created"
    RUNNING = "running"
    STOPPED = "stopped"


class TradeSide(StrEnum):
    BUY = "buy"
    SELL = "sell"


class DecisionAction(StrEnum):
    BUY = "buy"
    SELL = "sell"
    HOLD = "hold"
