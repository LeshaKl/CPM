from datetime import datetime

from sqlalchemy import DateTime, Enum, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import BotStatus


class Bot(Base):
    __tablename__ = "bots"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    symbol: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    strategy_name: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[BotStatus] = mapped_column(
        Enum(BotStatus, native_enum=False),
        default=BotStatus.CREATED,
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    portfolio = relationship(
        "Portfolio",
        back_populates="bot",
        uselist=False,
        cascade="all, delete-orphan",
    )
    trades = relationship("Trade", back_populates="bot", cascade="all, delete-orphan")
    decisions = relationship("DecisionLog", back_populates="bot", cascade="all, delete-orphan")
