from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.models.enums import TradeSide


class TradeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    bot_id: int
    symbol: str
    side: TradeSide
    price: float
    amount: float
    created_at: datetime
