from __future__ import annotations

from threading import Event, Thread
from time import sleep

from sqlalchemy import select

from app.core.config import get_settings
from app.core.database import SessionLocal
from app.models.bot import Bot
from app.models.enums import BotStatus
from app.services.trading_engine import run_bot_tick


class BotRunner:
    def __init__(self) -> None:
        settings = get_settings()
        self.interval_seconds = settings.bot_runner_interval_seconds
        self._stop_event = Event()
        self._thread = Thread(target=self._loop, name="bot-runner", daemon=True)

    def start(self) -> None:
        if not self._thread.is_alive():
            self._thread.start()

    def stop(self) -> None:
        self._stop_event.set()
        if self._thread.is_alive():
            self._thread.join(timeout=2)

    def _loop(self) -> None:
        while not self._stop_event.is_set():
            self._tick_running_bots()
            sleep(self.interval_seconds)

    def _tick_running_bots(self) -> None:
        with SessionLocal() as db:
            bot_ids = list(db.scalars(select(Bot.id).where(Bot.status == BotStatus.RUNNING)).all())

        for bot_id in bot_ids:
            with SessionLocal() as db:
                try:
                    run_bot_tick(db=db, bot_id=bot_id)
                except Exception:
                    db.rollback()
