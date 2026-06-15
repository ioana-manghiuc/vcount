from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import logging
import torch
import logging.config
from app.logging.logging_config import LOGGING_CONFIG
from app.routers import frames, results, processing, bulk_processing
logging.config.dictConfig(LOGGING_CONFIG)

logger = logging.getLogger("app")

app = FastAPI()

@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info("%s %s", request.method, request.url.path)
    response = await call_next(request)
    logger.info("→ %d", response.status_code)
    logger.info("CUDA available: %s — device: %s",
            torch.cuda.is_available(),
            torch.cuda.get_device_name(0) if torch.cuda.is_available() else "CPU")
    return response

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(frames.router)
app.include_router(results.router)
app.include_router(processing.router)
app.include_router(bulk_processing.router)