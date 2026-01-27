"""Results file serving endpoints."""
import os
import logging
from pathlib import Path
from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

logger = logging.getLogger("app")

router = APIRouter(prefix="/results", tags=["results"])

RESULTS_FOLDER = Path("results")
RESULTS_FOLDER.mkdir(exist_ok=True)


@router.get("/{filename}")
def get_result_file(filename: str):
    """Serve result files (JSON, videos, images)."""
    logger.info("Serving result file: %s", filename)

    path = os.path.join(RESULTS_FOLDER, filename)
    if not os.path.exists(path):
        raise HTTPException(404)

    media_type = "application/octet-stream"
    if filename.endswith('.json'):
        media_type = "application/json"
    elif filename.endswith('.mp4'):
        media_type = "video/mp4"
    elif filename.endswith('.png'):
        media_type = "image/png"

    return FileResponse(path, media_type=media_type)
