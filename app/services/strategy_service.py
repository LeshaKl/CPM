from app.strategies.base import BaseStrategy
from app.strategies.ai_agent_strategy import AIAgentStrategy
from app.strategies.simple_strategy import SimpleStrategy


def get_strategy(strategy_name: str) -> BaseStrategy:
    strategies: dict[str, BaseStrategy] = {
        AIAgentStrategy.name: AIAgentStrategy(),
        SimpleStrategy.name: SimpleStrategy(),
    }

    if strategy_name not in strategies:
        raise ValueError(f"Unsupported strategy: {strategy_name}")

    return strategies[strategy_name]
