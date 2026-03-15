from datetime import datetime

from pydantic import BaseModel, ConfigDict


class PortfolioResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    bot_id: int
    cash_balance: float
    asset_balance: float
    total_value: float
    updated_at: datetime
