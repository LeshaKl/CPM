from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.models.enums import DecisionAction


class DecisionLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    bot_id: int
    action: DecisionAction
    reason: str
    price_snapshot: float
    created_at: datetime
