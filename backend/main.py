"""fastapi сервер icerock intelligence - rest api + websocket для live логов"""

from __future__ import annotations

import asyncio
import json
import os
from collections import defaultdict
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from dotenv import load_dotenv
from fastapi import Depends, FastAPI, WebSocket, WebSocketDisconnect, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import desc
from sqlalchemy.orm import Session

from backend.agent import AIAgent
from backend.backtest import BacktestEngine
from backend.database import get_db, init_db
from backend.models import Bot, BotStatus, DecisionLog, PerformanceMetric, Trade
from backend.schemas import (
    AnalyzeResponse,
    BacktestResponse,
    BotCreate,
    BotResponse,
    DashboardResponse,
    DecisionResponse,
    MetricResponse,
    TradeResponse,
)

load_dotenv()

log_subscribers: dict[int, list[WebSocket]] = defaultdict(list)


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield

app = FastAPI(title="Icerock Intelligence API", version="1.0.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

backtest_engine = BacktestEngine()
ai_agent = AIAgent()


async def broadcast_log(bot_id: int, message: str) -> None:
    entry = json.dumps({
        "bot_id": bot_id,
        "message": message,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    })
    dead: list[WebSocket] = []
    for ws in log_subscribers.get(bot_id, []):
        try:
            await ws.send_text(entry)
        except Exception:
            dead.append(ws)
    for ws in dead:
        log_subscribers[bot_id].remove(ws)


def _bot_to_response(db: Session, bot: Bot) -> BotResponse:
    latest = (
        db.query(PerformanceMetric)
        .filter(PerformanceMetric.bot_id == bot.id)
        .order_by(desc(PerformanceMetric.timestamp))
        .first()
    )
    metric = None
    if latest:
        metric = MetricResponse.model_validate(latest)
    return BotResponse(
        id=bot.id,
        name=bot.name,
        symbol=bot.symbol,
        strategy=bot.strategy,
        status=bot.status.value,
        initial_capital=bot.initial_capital,
        created_at=bot.created_at,
        latest_metric=metric,
    )


@app.post("/bots", response_model=BotResponse, status_code=status.HTTP_201_CREATED)
def create_bot(payload: BotCreate, db: Session = Depends(get_db)) -> BotResponse:
    bot = Bot(
        name=payload.name,
        symbol=payload.symbol.upper(),
        strategy=payload.strategy,
        initial_capital=payload.initial_capital,
    )
    db.add(bot)
    db.commit()
    db.refresh(bot)
    return _bot_to_response(db, bot)


@app.get("/bots", response_model=list[BotResponse])
def list_bots(db: Session = Depends(get_db)) -> list[BotResponse]:
    bots = db.query(Bot).order_by(Bot.created_at.desc()).all()
    return [_bot_to_response(db, b) for b in bots]


@app.get("/bots/{bot_id}", response_model=BotResponse)
def get_bot(bot_id: int, db: Session = Depends(get_db)) -> BotResponse:
    bot = db.query(Bot).filter(Bot.id == bot_id).first()
    if not bot:
        return JSONResponse(status_code=404, content={"detail": "Bot not found"})
    return _bot_to_response(db, bot)


@app.post("/bots/{bot_id}/start")
def start_bot(bot_id: int, db: Session = Depends(get_db)):
    bot = db.query(Bot).filter(Bot.id == bot_id).first()
    if not bot:
        return JSONResponse(status_code=404, content={"detail": "Bot not found"})
    bot.status = BotStatus.ACTIVE
    db.commit()
    return {"status": "active", "bot_id": bot_id}


@app.post("/bots/{bot_id}/stop")
def stop_bot(bot_id: int, db: Session = Depends(get_db)):
    bot = db.query(Bot).filter(Bot.id == bot_id).first()
    if not bot:
        return JSONResponse(status_code=404, content={"detail": "Bot not found"})
    bot.status = BotStatus.STOPPED
    db.commit()
    return {"status": "stopped", "bot_id": bot_id}


@app.post("/bots/{bot_id}/backtest", response_model=BacktestResponse)
def run_backtest(bot_id: int, period: str = "6mo", db: Session = Depends(get_db)):
    bot = db.query(Bot).filter(Bot.id == bot_id).first()
    if not bot:
        return JSONResponse(status_code=404, content={"detail": "Bot not found"})
    try:
        result = backtest_engine.run(db, bot, period)
    except ValueError as exc:
        return JSONResponse(status_code=400, content={"detail": str(exc)})
    return BacktestResponse(
        bot_id=bot_id,
        trades_count=len(result.trades),
        final_equity=result.final_equity,
        pnl=result.pnl,
        pnl_percent=result.pnl_percent,
        sharpe=result.sharpe,
        max_drawdown=result.max_drawdown,
        win_rate=result.win_rate,
    )


@app.post("/bots/{bot_id}/analyze", response_model=AnalyzeResponse)
def analyze_bot(bot_id: int, db: Session = Depends(get_db)):
    bot = db.query(Bot).filter(Bot.id == bot_id).first()
    if not bot:
        return JSONResponse(status_code=404, content={"detail": "Bot not found"})
    decision = ai_agent.analyze(db, bot)
    return AnalyzeResponse(
        bot_id=bot_id,
        action=decision.action,
        reasoning=decision.reasoning,
        confidence=decision.confidence,
    )


@app.get("/bots/{bot_id}/trades", response_model=list[TradeResponse])
def get_trades(bot_id: int, limit: int = 50, db: Session = Depends(get_db)):
    trades = (
        db.query(Trade)
        .filter(Trade.bot_id == bot_id)
        .order_by(desc(Trade.timestamp))
        .limit(limit)
        .all()
    )
    return [TradeResponse.model_validate(t) for t in trades]


@app.get("/bots/{bot_id}/metrics", response_model=list[MetricResponse])
def get_metrics(bot_id: int, limit: int = 100, db: Session = Depends(get_db)):
    metrics = (
        db.query(PerformanceMetric)
        .filter(PerformanceMetric.bot_id == bot_id)
        .order_by(desc(PerformanceMetric.timestamp))
        .limit(limit)
        .all()
    )
    return [MetricResponse.model_validate(m) for m in metrics]


@app.get("/bots/{bot_id}/decisions", response_model=list[DecisionResponse])
def get_decisions(bot_id: int, limit: int = 20, db: Session = Depends(get_db)):
    decisions = (
        db.query(DecisionLog)
        .filter(DecisionLog.bot_id == bot_id)
        .order_by(desc(DecisionLog.timestamp))
        .limit(limit)
        .all()
    )
    return [DecisionResponse.model_validate(d) for d in decisions]


@app.get("/dashboard", response_model=DashboardResponse)
def get_dashboard(db: Session = Depends(get_db)):
    bots = db.query(Bot).all()
    total_equity = 0.0
    total_pnl = 0.0
    sharpe_values: list[float] = []
    best_bot_name = None
    best_bot_pnl = 0.0
    equity_history: list[dict] = []

    for bot in bots:
        metric = (
            db.query(PerformanceMetric)
            .filter(PerformanceMetric.bot_id == bot.id)
            .order_by(desc(PerformanceMetric.timestamp))
            .first()
        )
        if metric:
            total_equity += metric.equity
            total_pnl += metric.pnl
            sharpe_values.append(metric.sharpe)
            if metric.pnl > best_bot_pnl:
                best_bot_pnl = metric.pnl
                best_bot_name = bot.name

        all_metrics = (
            db.query(PerformanceMetric)
            .filter(PerformanceMetric.bot_id == bot.id)
            .order_by(PerformanceMetric.timestamp)
            .all()
        )
        for m in all_metrics:
            equity_history.append({
                "bot": bot.name,
                "equity": m.equity,
                "timestamp": m.timestamp.isoformat() if m.timestamp else "",
            })

    active_count = sum(1 for b in bots if b.status == BotStatus.ACTIVE)
    avg_sharpe = sum(sharpe_values) / len(sharpe_values) if sharpe_values else 0.0

    return DashboardResponse(
        total_bots=len(bots),
        active_bots=active_count,
        total_equity=round(total_equity, 2),
        total_pnl=round(total_pnl, 2),
        avg_sharpe=round(avg_sharpe, 2),
        best_bot_name=best_bot_name,
        best_bot_pnl=round(best_bot_pnl, 2),
        equity_history=equity_history,
    )


@app.delete("/bots/{bot_id}")
def delete_bot(bot_id: int, db: Session = Depends(get_db)):
    bot = db.query(Bot).filter(Bot.id == bot_id).first()
    if not bot:
        return JSONResponse(status_code=404, content={"detail": "Bot not found"})
    db.delete(bot)
    db.commit()
    return {"deleted": True, "bot_id": bot_id}


@app.websocket("/ws/logs/{bot_id}")
async def websocket_logs(websocket: WebSocket, bot_id: int):
    await websocket.accept()
    log_subscribers[bot_id].append(websocket)
    try:
        while True:
            await asyncio.sleep(1)
            try:
                await websocket.receive_text()
            except WebSocketDisconnect:
                break
    except Exception:
        pass
    finally:
        if websocket in log_subscribers[bot_id]:
            log_subscribers[bot_id].remove(websocket)
