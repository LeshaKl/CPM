from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import BotStatus


class BotCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    symbol: str = Field(min_length=1, max_length=50)
    strategy_name: str = Field(default="simple_strategy", min_length=1, max_length=50)


class BotResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    symbol: str
    strategy_name: str
    status: BotStatus
    created_at: datetime


class BotStatusResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    status: BotStatus
