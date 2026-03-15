# Icerock Intelligence

AI-система управления торговыми ботами. Python-бэкенд (FastAPI) + SwiftUI-фронтенд (iOS / iPadOS / macOS).

**Команда C+- | HSE VibeHACK March 2026**

Klushin Aleksey · Karpov Aleksey · Belyavskiy Denis · Balenkov Ilya

---

## Архитектура

```
┌─────────────────────────────────────────┐
│         SwiftUI App (iOS/macOS)         │
│                                         │
│  HomeView ─ BotsListView ─ Analytics    │
│       │           │                     │
│  BotViewModel ←── APIService (REST)     │
│                   WebSocketManager (WS) │
└────────────┬────────────────┬───────────┘
             │ HTTP/REST      │ WebSocket
┌────────────▼────────────────▼───────────┐
│         FastAPI Backend (Python)        │
│                                         │
│  Endpoints ── BacktestEngine (yfinance) │
│            ── AIAgent (Groq LLM)        │
│            ── SQLite (SQLAlchemy)        │
└─────────────────────────────────────────┘
```

---

## Что умеет система

- **Создание торговых ботов** — выбираешь тикер (AAPL, TSLA, SBER.ME), стратегию, начальный капитал
- **Бэктест на исторических данных** — yfinance качает реальные данные, прогоняет стратегию (SMA Crossover / Momentum / Mean Reversion)
- **AI-анализ через Groq** — LLM (LLaMA 3.3 70B) анализирует метрики бота и даёт рекомендации (hold/rebalance/increase/decrease)
- **Дашборд** — совокупный капитал, PnL, Sharpe, equity chart, system health
- **Инспектор бота** — equity curve, история сделок, AI reasoning log, live logs
- **Аналитика** — рейтинг ботов по PnL, разбивка по стратегиям, агрегированные метрики

---

## Требования

| Компонент | Минимум |
|-----------|---------|
| macOS | 14.0 Sonoma+ |
| Xcode | 15.0+ |
| Python | 3.11+ |
| RAM | 8 GB |
| iOS (опционально) | 17.0+ |

---

## Быстрый старт

### Шаг 1. Клонировать репозиторий

```bash
git clone https://github.com/LeshaKl/CPM.git
cd CPM
```

### Шаг 2. Получить бесплатный Groq API Key

1. Открой [console.groq.com](https://console.groq.com)
2. Зарегистрируйся (через Google/GitHub — бесплатно)
3. Перейди в **API Keys** → **Create API Key**
4. Скопируй ключ (начинается с `gsk_...`)

> Бесплатный tier Groq: 30 запросов/минуту, 14,400 запросов/день — более чем достаточно.

### Шаг 3. Настроить и запустить бэкенд

```bash
cd backend

# создаём виртуальное окружение
python3 -m venv .venv
source .venv/bin/activate

# ставим зависимости
pip install -r requirements.txt

# создаём .env с ключом Groq
cp .env.example .env
# отредактируй .env — вставь свой GROQ_API_KEY

# запускаем сервер
uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```

Сервер запустится на `http://127.0.0.1:8000`. Swagger UI доступен на `http://127.0.0.1:8000/docs`.

> **Важно:** команду `uvicorn` запускай из корня проекта (не из папки `backend/`), потому что модуль называется `backend.main`.

### Шаг 4. Проверить бэкенд (опционально)

```bash
# создать бота
curl -X POST http://127.0.0.1:8000/bots \
  -H "Content-Type: application/json" \
  -d '{"name": "Alpha Bot", "symbol": "AAPL", "strategy": "sma_crossover"}'

# запустить бэктест
curl -X POST http://127.0.0.1:8000/bots/1/backtest

# запросить AI-анализ
curl -X POST http://127.0.0.1:8000/bots/1/analyze

# получить дашборд
curl http://127.0.0.1:8000/dashboard
```

### Шаг 5. Открыть и собрать SwiftUI-приложение

1. Открой Xcode
2. **File → New → Project → Multiplatform → App**
3. Назови проект **IcerockIntelligence**
4. Удали сгенерированные файлы (`ContentView.swift`, `Item.swift`)
5. Перетащи всё содержимое папки `IcerockIntelligence/IcerockIntelligence/` в проект Xcode
6. Структура файлов в Xcode:

```
IcerockIntelligence/
├── IcerockIntelligenceApp.swift    ← точка входа (@main)
├── ContentView.swift               ← TabView / NavigationSplitView
├── Models.swift                    ← модели данных + цвета
├── Services/
│   ├── APIService.swift            ← REST-клиент
│   └── WebSocketManager.swift      ← WebSocket для live логов
├── ViewModels/
│   └── BotViewModel.swift          ← MVVM state management
└── Views/
    ├── HomeView.swift              ← главная с дашбордом
    ├── BotsListView.swift          ← список ботов
    ├── BotDetailView.swift         ← инспектор бота
    ├── LogView.swift               ← live логи
    ├── AnalyticsView.swift         ← аналитика
    ├── SettingsView.swift          ← настройки
    └── Components/
        ├── GlassCard.swift         ← glassmorphism-карточка
        ├── MiniChartView.swift     ← sparkline
        ├── EquityChartView.swift   ← интерактивный chart
        └── StatusBadge.swift       ← badge статуса бота
```

7. Убедись, что **Deployment Target** установлен:
   - iOS: **17.0**
   - macOS: **14.0**

8. Удали `IceRockApp.swift` если Xcode добавил его автоматически (точка входа — `IcerockIntelligenceApp.swift`)

9. Нажми **Cmd+R** для запуска

### Шаг 6. Запуск на iPhone / iPad

1. Подключи устройство по USB
2. В Xcode выбери своё устройство в списке targets
3. Первый раз: **Settings → General → VPN & Device Management** → доверяй своему сертификату разработчика
4. В `SettingsView` приложения измени API URL на IP твоего мака в локальной сети:
   ```
   http://192.168.x.x:8000
   ```
5. Убедись, что мак и айфон в одной Wi-Fi сети

### Шаг 7. Запуск на Mac (нативно)

1. В Xcode выбери target **My Mac** (не Designed for iPad)
2. Cmd+R — приложение откроется с sidebar-навигацией вместо TabView

---

## API Endpoints

| Метод | Путь | Описание |
|-------|------|----------|
| POST | `/bots` | Создать бота |
| GET | `/bots` | Список всех ботов |
| GET | `/bots/{id}` | Детали бота |
| POST | `/bots/{id}/start` | Запустить бота |
| POST | `/bots/{id}/stop` | Остановить бота |
| POST | `/bots/{id}/backtest` | Запустить бэктест |
| POST | `/bots/{id}/analyze` | AI-анализ (Groq) |
| GET | `/bots/{id}/trades` | История сделок |
| GET | `/bots/{id}/metrics` | Метрики |
| GET | `/bots/{id}/decisions` | AI-решения |
| GET | `/dashboard` | Агрегированный дашборд |
| DELETE | `/bots/{id}` | Удалить бота |
| WS | `/ws/logs/{id}` | Live логи (WebSocket) |

---

## Стратегии бэктеста

| Стратегия | Описание |
|-----------|----------|
| `sma_crossover` | Покупка когда SMA(10) > SMA(30), продажа наоборот |
| `momentum` | Покупка при росте >2% за 14 дней, продажа при падении |
| `mean_reversion` | Покупка при z-score < -1.5, продажа при z-score > 1.5 |

---

## AI Agent (Groq)

Использует модель **LLaMA 3.3 70B Versatile** через Groq API.

Агент анализирует:
- Equity, PnL, Sharpe ratio
- Max drawdown, win rate
- Историю последних сделок

И возвращает одно из решений:
- **hold** — продолжить текущую стратегию
- **increase_position** — увеличить позицию (хорошие метрики)
- **decrease_position** — сократить позицию (высокий drawdown)
- **rebalance** — перебалансировать (PnL отрицательный)
- **stop** — остановить бота (критический drawdown)

> Если Groq API Key не задан, агент работает по правилам (rule-based fallback).

---

## Дизайн

Тёмная тема в стиле glassmorphism:
- Фон: `#080c14`
- Карточки: `#111828` с border `#1a2340`
- Акцент: `#4f6ef7` (синий)
- Profit: `#34d399` (зелёный), Loss: `#f87171` (красный)
- SF Symbols для всех иконок
- Spring-анимации на переходах, pulse на статусах, path-анимации на графиках

---

## Troubleshooting

**Бэкенд не запускается:**
```bash
# убедись что запускаешь из корня проекта
cd CPM
uvicorn backend.main:app --reload
```

**yfinance не возвращает данные:**
- Проверь интернет-соединение
- Некоторые тикеры (.ME для MOEX) могут быть недоступны в выходные

**Приложение не подключается к серверу:**
- Проверь что сервер запущен (`http://127.0.0.1:8000/docs`)
- На реальном устройстве используй IP мака, не `localhost`
- Xcode: **Project → Info → App Transport Security Settings → Allow Arbitrary Loads → YES**

**Groq API ошибки:**
- Проверь что ключ в `.env` валидный
- Бесплатный tier: 30 req/min — не спамь analyze

---

## Технологии

**Backend:** Python 3.11, FastAPI, SQLAlchemy, SQLite, yfinance, Groq API, httpx

**Frontend:** Swift 5.9, SwiftUI, MVVM, URLSession, WebSocket, SF Symbols

**AI:** LLaMA 3.3 70B (Groq) — бесплатный tier, JSON-structured output
