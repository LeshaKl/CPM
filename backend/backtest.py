"""бэктест-движок - скачивает данные через yfinance, прогоняет стратегию, сохраняет результаты"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from datetime import datetime, timezone

import yfinance as yf
from sqlalchemy.orm import Session

from backend.models import Bot, BotStatus, PerformanceMetric, Trade, TradeSide


@dataclass
class BacktestResult:
    trades: list[dict] = field(default_factory=list)
    equity_curve: list[float] = field(default_factory=list)
    final_equity: float = 0.0
    pnl: float = 0.0
    pnl_percent: float = 0.0
    sharpe: float = 0.0
    max_drawdown: float = 0.0
    win_rate: float = 0.0


class BacktestEngine:
    """прогоняет стратегию на исторических данных и сохраняет результат в бд"""

    STRATEGIES = {"sma_crossover", "momentum", "mean_reversion"}

    def run(self, db: Session, bot: Bot, period: str = "6mo") -> BacktestResult:
        bot.status = BotStatus.ANALYZING
        db.commit()

        try:
            prices = self._fetch_prices(bot.symbol, period)
            if len(prices) < 30:
                raise ValueError(f"Недостаточно данных для {bot.symbol}: {len(prices)} точек")

            result = self._execute_strategy(bot.strategy, prices, bot.initial_capital)
            self._save_results(db, bot, result, prices)
            return result
        finally:
            bot.status = BotStatus.STOPPED
            db.commit()

    def _fetch_prices(self, symbol: str, period: str) -> list[tuple[datetime, float]]:
        ticker = yf.Ticker(symbol)
        hist = ticker.history(period=period, interval="1d")
        if hist.empty:
            raise ValueError(f"yfinance не вернул данных для {symbol}")
        return [
            (idx.to_pydatetime().replace(tzinfo=timezone.utc), row["Close"])
            for idx, row in hist.iterrows()
        ]

    def _execute_strategy(
        self, strategy: str, prices: list[tuple[datetime, float]], capital: float
    ) -> BacktestResult:
        if strategy == "sma_crossover":
            return self._sma_crossover(prices, capital)
        if strategy == "momentum":
            return self._momentum(prices, capital)
        if strategy == "mean_reversion":
            return self._mean_reversion(prices, capital)
        return self._sma_crossover(prices, capital)

    def _sma_crossover(
        self, prices: list[tuple[datetime, float]], capital: float, short: int = 10, long: int = 30
    ) -> BacktestResult:
        cash = capital
        position = 0.0
        trades: list[dict] = []
        equity_curve: list[float] = []
        close_prices = [p for _, p in prices]

        for i in range(long, len(prices)):
            sma_short = sum(close_prices[i - short : i]) / short
            sma_long = sum(close_prices[i - long : i]) / long
            timestamp, price = prices[i]
            equity = cash + position * price

            if sma_short > sma_long and position == 0 and cash > price:
                amount = (cash * 0.95) / price
                position = amount
                cash -= amount * price
                trades.append({"side": "buy", "price": price, "amount": amount, "timestamp": timestamp})

            elif sma_short < sma_long and position > 0:
                cash += position * price
                trades.append({"side": "sell", "price": price, "amount": position, "timestamp": timestamp})
                position = 0.0

            equity_curve.append(cash + position * price)

        final_equity = cash + position * close_prices[-1]
        return self._build_result(trades, equity_curve, final_equity, capital)

    def _momentum(self, prices: list[tuple[datetime, float]], capital: float, lookback: int = 14) -> BacktestResult:
        cash = capital
        position = 0.0
        trades: list[dict] = []
        equity_curve: list[float] = []
        close_prices = [p for _, p in prices]

        for i in range(lookback, len(prices)):
            timestamp, price = prices[i]
            returns = (price - close_prices[i - lookback]) / close_prices[i - lookback]

            if returns > 0.02 and position == 0 and cash > price:
                amount = (cash * 0.95) / price
                position = amount
                cash -= amount * price
                trades.append({"side": "buy", "price": price, "amount": amount, "timestamp": timestamp})

            elif returns < -0.02 and position > 0:
                cash += position * price
                trades.append({"side": "sell", "price": price, "amount": position, "timestamp": timestamp})
                position = 0.0

            equity_curve.append(cash + position * price)

        final_equity = cash + position * close_prices[-1]
        return self._build_result(trades, equity_curve, final_equity, capital)

    def _mean_reversion(
        self, prices: list[tuple[datetime, float]], capital: float, window: int = 20, threshold: float = 1.5
    ) -> BacktestResult:
        cash = capital
        position = 0.0
        trades: list[dict] = []
        equity_curve: list[float] = []
        close_prices = [p for _, p in prices]

        for i in range(window, len(prices)):
            timestamp, price = prices[i]
            window_prices = close_prices[i - window : i]
            mean = sum(window_prices) / len(window_prices)
            std = (sum((p - mean) ** 2 for p in window_prices) / len(window_prices)) ** 0.5
            z_score = (price - mean) / std if std > 0 else 0

            if z_score < -threshold and position == 0 and cash > price:
                amount = (cash * 0.95) / price
                position = amount
                cash -= amount * price
                trades.append({"side": "buy", "price": price, "amount": amount, "timestamp": timestamp})

            elif z_score > threshold and position > 0:
                cash += position * price
                trades.append({"side": "sell", "price": price, "amount": position, "timestamp": timestamp})
                position = 0.0

            equity_curve.append(cash + position * price)

        final_equity = cash + position * close_prices[-1]
        return self._build_result(trades, equity_curve, final_equity, capital)

    def _build_result(
        self, trades: list[dict], equity_curve: list[float], final_equity: float, capital: float
    ) -> BacktestResult:
        pnl = final_equity - capital
        pnl_percent = (pnl / capital) * 100 if capital > 0 else 0

        returns = []
        for i in range(1, len(equity_curve)):
            if equity_curve[i - 1] > 0:
                returns.append((equity_curve[i] - equity_curve[i - 1]) / equity_curve[i - 1])

        sharpe = 0.0
        if returns:
            avg_return = sum(returns) / len(returns)
            std_return = (sum((r - avg_return) ** 2 for r in returns) / len(returns)) ** 0.5
            if std_return > 0:
                sharpe = round((avg_return / std_return) * math.sqrt(252), 2)

        max_drawdown = 0.0
        peak = capital
        for eq in equity_curve:
            peak = max(peak, eq)
            drawdown = (peak - eq) / peak if peak > 0 else 0
            max_drawdown = max(max_drawdown, drawdown)

        winning = 0
        sell_trades = [t for t in trades if t["side"] == "sell"]
        buy_trades = [t for t in trades if t["side"] == "buy"]
        for i, sell in enumerate(sell_trades):
            if i < len(buy_trades) and sell["price"] > buy_trades[i]["price"]:
                winning += 1
        win_rate = (winning / len(sell_trades) * 100) if sell_trades else 0

        return BacktestResult(
            trades=trades,
            equity_curve=equity_curve,
            final_equity=round(final_equity, 2),
            pnl=round(pnl, 2),
            pnl_percent=round(pnl_percent, 2),
            sharpe=sharpe,
            max_drawdown=round(max_drawdown * 100, 2),
            win_rate=round(win_rate, 1),
        )

    def _save_results(
        self, db: Session, bot: Bot, result: BacktestResult, prices: list[tuple[datetime, float]]
    ) -> None:
        for trade_data in result.trades:
            db.add(Trade(
                bot_id=bot.id,
                side=TradeSide(trade_data["side"]),
                symbol=bot.symbol,
                price=trade_data["price"],
                amount=trade_data["amount"],
                timestamp=trade_data["timestamp"],
            ))

        db.add(PerformanceMetric(
            bot_id=bot.id,
            equity=result.final_equity,
            pnl=result.pnl,
            pnl_percent=result.pnl_percent,
            sharpe=result.sharpe,
            max_drawdown=result.max_drawdown,
            win_rate=result.win_rate,
            total_trades=len(result.trades),
        ))
        db.commit()
