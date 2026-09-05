import importlib.util
import shutil

from fastapi import FastAPI
from fastapi.responses import JSONResponse

from app.routes import router

app = FastAPI(title="Piano-Tool Ingestion Service")
app.include_router(router)


@app.get("/health", response_model=dict[str, str])
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/ready", response_model=dict[str, str])
def ready() -> dict[str, str] | JSONResponse:
    missing = [binary for binary in ("ffmpeg", "ffprobe") if shutil.which(binary) is None]
    if importlib.util.find_spec("basic_pitch") is None:
        missing.append("basic_pitch")
    if missing:
        return JSONResponse(
            status_code=503, content={"status": "not_ready", "missing": ",".join(missing)}
        )
    return {"status": "ready"}
