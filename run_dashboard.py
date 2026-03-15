import os
from threading import Timer
import webbrowser

import uvicorn


HOST = "127.0.0.1"
PORT = 8000
TBANK_TOKEN = "t.hvj9ehsGNn_eumJspy33FiEzF52hTQdq67yxlHHJyIOzPDw4aufntfHHDtVKZgA0ZugxA5j04BhixxVx0-UTxA"


def open_dashboard() -> None:
    webbrowser.open(f"http://{HOST}:{PORT}/dashboard")


if __name__ == "__main__":
    os.environ.setdefault("MARKET_DATA_PROVIDER", "tbank")
    os.environ.setdefault("MARKET_DATA_API_TOKEN", TBANK_TOKEN)
    os.environ.setdefault("TBANK_DEFAULT_CLASS_CODE", "TQBR")
    os.environ.setdefault("MARKET_DATA_VERIFY_SSL", "false")
    Timer(1.2, open_dashboard).start()
    uvicorn.run("app.main:app", host=HOST, port=PORT, reload=False)
