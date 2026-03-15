class AppError(Exception):
    """Base application exception."""


class BotNotFoundError(AppError):
    pass


class BotNotRunningError(AppError):
    pass


class InsufficientFundsError(AppError):
    pass


class InsufficientAssetBalanceError(AppError):
    pass
