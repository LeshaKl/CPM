from pathlib import Path

from fastapi import APIRouter
from fastapi.responses import HTMLResponse


router = APIRouter(tags=["dashboard"])
_DASHBOARD_PATH = Path(__file__).resolve().parent.parent / "ui" / "dashboard.html"


@router.get("/dashboard", response_class=HTMLResponse)
def get_dashboard() -> HTMLResponse:
    return HTMLResponse(_DASHBOARD_PATH.read_text(encoding="utf-8"))
