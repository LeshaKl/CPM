"""ai-агент для анализа торговых ботов - вызывает groq api, возвращает json с рекомендациями"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass

import httpx
from sqlalchemy.orm import Session

from backend.models import Bot, BotStatus, DecisionLog, PerformanceMetric, Trade

GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "llama-3.3-70b-versatile"


@dataclass
class AgentDecision:
    action: str
    reasoning: str
    confidence: float


SYSTEM_PROMPT = """Ты — AI-аналитик торговых ботов системы Icerock Intelligence.
Тебе дают метрики производительности бота и его историю сделок.
Проанализируй данные и верни JSON с рекомендациями.

Формат ответа (строго JSON, без markdown):
{
  "action": "hold" | "increase_position" | "decrease_position" | "rebalance" | "stop",
  "reasoning": "детальное объяснение на русском языке, 2-4 предложения",
  "confidence": 0.0-1.0
}

Правила:
- Если Sharpe > 1.5 и win rate > 60% — рекомендуй increase_position
- Если max drawdown > 20% — рекомендуй decrease_position или stop
- Если PnL отрицательный но Sharpe приемлемый — рекомендуй rebalance
- Если всё стабильно — рекомендуй hold
- confidence отражает уверенность в рекомендации"""


class AIAgent:
    """анализирует производительность бота через groq llm и возвращает рекомендации"""

    def __init__(self) -> None:
        self.api_key = os.getenv("GROQ_API_KEY", "")

    def analyze(self, db: Session, bot: Bot) -> AgentDecision:
        if not self.api_key:
            return self._fallback_analysis(db, bot)

        bot.status = BotStatus.ANALYZING
        db.commit()

        try:
            context = self._build_context(db, bot)
            decision = self._call_groq(context)
            self._save_decision(db, bot, decision)
            return decision
        except Exception as exc:
            fallback = AgentDecision(
                action="hold",
                reasoning=f"AI анализ временно недоступен ({exc}). Рекомендуем удержание позиций.",
                confidence=0.3,
            )
            self._save_decision(db, bot, fallback)
            return fallback
        finally:
            bot.status = BotStatus.ACTIVE if bot.status == BotStatus.ANALYZING else bot.status
            db.commit()

    def _build_context(self, db: Session, bot: Bot) -> str:
        latest_metric = (
            db.query(PerformanceMetric)
            .filter(PerformanceMetric.bot_id == bot.id)
            .order_by(PerformanceMetric.timestamp.desc())
            .first()
        )
        recent_trades = (
            db.query(Trade)
            .filter(Trade.bot_id == bot.id)
            .order_by(Trade.timestamp.desc())
            .limit(20)
            .all()
        )

        metric_str = "Нет данных"
        if latest_metric:
            metric_str = (
                f"Equity: ${latest_metric.equity:.2f}, "
                f"PnL: ${latest_metric.pnl:.2f} ({latest_metric.pnl_percent:.1f}%), "
                f"Sharpe: {latest_metric.sharpe:.2f}, "
                f"Max Drawdown: {latest_metric.max_drawdown:.1f}%, "
                f"Win Rate: {latest_metric.win_rate:.1f}%, "
                f"Total Trades: {latest_metric.total_trades}"
            )

        trades_str = "Нет сделок"
        if recent_trades:
            lines = []
            for t in recent_trades[:10]:
                lines.append(f"  {t.side.value} {t.amount:.4f} @ ${t.price:.2f}")
            trades_str = "\n".join(lines)

        return (
            f"Бот: {bot.name}\n"
            f"Тикер: {bot.symbol}\n"
            f"Стратегия: {bot.strategy}\n"
            f"Начальный капитал: ${bot.initial_capital:.2f}\n\n"
            f"Метрики:\n{metric_str}\n\n"
            f"Последние сделки:\n{trades_str}"
        )

    def _call_groq(self, context: str) -> AgentDecision:
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": GROQ_MODEL,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": context},
            ],
            "temperature": 0.3,
            "max_tokens": 500,
            "response_format": {"type": "json_object"},
        }

        with httpx.Client(timeout=30) as client:
            response = client.post(GROQ_API_URL, headers=headers, json=payload)
            response.raise_for_status()

        data = response.json()
        content = data["choices"][0]["message"]["content"]
        parsed = json.loads(content)

        return AgentDecision(
            action=parsed.get("action", "hold"),
            reasoning=parsed.get("reasoning", "Нет данных"),
            confidence=float(parsed.get("confidence", 0.5)),
        )

    def _fallback_analysis(self, db: Session, bot: Bot) -> AgentDecision:
        """правила без llm - когда groq api key не задан"""
        latest_metric = (
            db.query(PerformanceMetric)
            .filter(PerformanceMetric.bot_id == bot.id)
            .order_by(PerformanceMetric.timestamp.desc())
            .first()
        )

        if not latest_metric:
            decision = AgentDecision(
                action="hold",
                reasoning="Нет метрик для анализа. Запустите бэктест перед анализом.",
                confidence=0.2,
            )
        elif latest_metric.max_drawdown > 20:
            decision = AgentDecision(
                action="decrease_position",
                reasoning=(
                    f"Высокий max drawdown ({latest_metric.max_drawdown:.1f}%). "
                    "Рекомендуется сократить позицию для снижения рисков."
                ),
                confidence=0.7,
            )
        elif latest_metric.sharpe > 1.5 and latest_metric.win_rate > 60:
            decision = AgentDecision(
                action="increase_position",
                reasoning=(
                    f"Sharpe {latest_metric.sharpe:.2f} и win rate {latest_metric.win_rate:.0f}% "
                    "выше порогов. Стратегия показывает устойчивую доходность."
                ),
                confidence=0.75,
            )
        elif latest_metric.pnl < 0:
            decision = AgentDecision(
                action="rebalance",
                reasoning=(
                    f"PnL отрицательный (${latest_metric.pnl:.2f}). "
                    "Рекомендуется ребалансировка или смена стратегии."
                ),
                confidence=0.6,
            )
        else:
            decision = AgentDecision(
                action="hold",
                reasoning="Показатели стабильны. Продолжайте текущую стратегию.",
                confidence=0.65,
            )

        self._save_decision(db, bot, decision)
        return decision

    def _save_decision(self, db: Session, bot: Bot, decision: AgentDecision) -> None:
        db.add(DecisionLog(
            bot_id=bot.id,
            action=decision.action,
            reasoning=decision.reasoning,
            confidence=decision.confidence,
        ))
        db.commit()
