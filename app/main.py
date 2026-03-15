from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse, RedirectResponse

from app.api.routes_bots import router as bots_router
from app.api.routes_dashboard import router as dashboard_router
from app.api.routes_market import router as market_router
from app.api.routes_portfolio import router as portfolio_router
from app.core.config import get_settings
from app.core.database import init_db
from app.core.exceptions import (
    AppError,
    BotNotFoundError,
    BotNotRunningError,
    InsufficientAssetBalanceError,
    InsufficientFundsError,
)
from app.services.bot_runner import BotRunner


bot_runner = BotRunner()


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    bot_runner.start()
    yield
    bot_runner.stop()


settings = get_settings()
app = FastAPI(title=settings.app_name, lifespan=lifespan)
app.include_router(bots_router)
app.include_router(dashboard_router)
app.include_router(market_router)
app.include_router(portfolio_router)


@app.get("/")
def root() -> RedirectResponse:
    return RedirectResponse(url="/dashboard", status_code=status.HTTP_307_TEMPORARY_REDIRECT)


@app.exception_handler(BotNotFoundError)
async def bot_not_found_handler(_: Request, exc: BotNotFoundError) -> JSONResponse:
    return JSONResponse(status_code=status.HTTP_404_NOT_FOUND, content={"detail": str(exc)})


@app.exception_handler(BotNotRunningError)
async def bot_not_running_handler(_: Request, exc: BotNotRunningError) -> JSONResponse:
    return JSONResponse(status_code=status.HTTP_409_CONFLICT, content={"detail": str(exc)})


@app.exception_handler(InsufficientFundsError)
async def insufficient_funds_handler(_: Request, exc: InsufficientFundsError) -> JSONResponse:
    return JSONResponse(status_code=status.HTTP_400_BAD_REQUEST, content={"detail": str(exc)})


@app.exception_handler(InsufficientAssetBalanceError)
async def insufficient_assets_handler(_: Request, exc: InsufficientAssetBalanceError) -> JSONResponse:
    return JSONResponse(status_code=status.HTTP_400_BAD_REQUEST, content={"detail": str(exc)})


@app.exception_handler(ValueError)
async def value_error_handler(_: Request, exc: ValueError) -> JSONResponse:
    return JSONResponse(status_code=status.HTTP_400_BAD_REQUEST, content={"detail": str(exc)})


@app.exception_handler(AppError)
async def app_error_handler(_: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(status_code=status.HTTP_400_BAD_REQUEST, content={"detail": str(exc)})
