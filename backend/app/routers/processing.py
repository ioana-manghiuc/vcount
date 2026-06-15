"""Single-video vehicle counting endpoint."""
import os
import json
import logging
import asyncio
from pathlib import Path
from uuid import uuid4
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor
from fastapi import APIRouter, UploadFile, File, Form, HTTPException

from app.utils.direction_validator import validate_directions
from app.services.counting_service import process_video
from app.utils import cancellation

logger = logging.getLogger("app")

router = APIRouter(prefix="", tags=["processing"])

executor = ThreadPoolExecutor(max_workers=2)

UPLOAD_FOLDER = Path("videos")
RESULTS_FOLDER = Path("results")
UPLOAD_FOLDER.mkdir(exist_ok=True)
RESULTS_FOLDER.mkdir(exist_ok=True)


@router.post("/count_vehicles")
async def count_vehicles(
    video: UploadFile = File(...),
    directions: str = Form(...),
    model_name: str = Form("yolo11n-best.pt"),
    intersection_name: str = Form(""),
    processing_id: str = Form(""),
):
    """Process a single video for vehicle counting with directional tracking."""
    try:
        logger.warning("count_vehicles called — processing_id=%s", processing_id)

        directions_data = json.loads(directions)
        validate_directions(directions_data)

        video_path = os.path.join(UPLOAD_FOLDER, f"{uuid4()}_{video.filename}")
        with open(video_path, "wb") as f:
            f.write(await video.read())

        cancellation.register_task(processing_id)
        logger.info("Registered task: %s", processing_id)

        loop = asyncio.get_event_loop()
        result = await loop.run_in_executor(
            executor,
            lambda: process_video(
                video_path=video_path,
                original_filename=video.filename or "unknown",
                directions_data=directions_data,
                model_name=model_name,
                processing_id=processing_id,
                annotated_filename_prefix="annotated",
            ),
        )

        if result["status"] == "cancelled":
            cancellation.mark_completed(processing_id)
            return {"status": "cancelled", "processing_id": processing_id}

        response_payload = {
            "results": result["results"],
            "metadata": {
                **result["metadata"],
                "intersection_name": intersection_name,
                "model": model_name,
                "directions_count": len(directions_data),
            },
        }

        result_filename = (
            f"results_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            f"_{uuid4().hex[:8]}.json"
        )
        with open(os.path.join(RESULTS_FOLDER, result_filename), "w") as f:
            json.dump(response_payload, f, indent=2)

        cancellation.mark_completed(processing_id)
        return response_payload

    except Exception as e:
        logger.exception("Vehicle counting failed")
        cancellation.mark_completed(processing_id, error=str(e))
        raise HTTPException(500, f"Vehicle counting failed: {str(e)}")


@router.post("/cancel_processing/{processing_id}")
def cancel_processing(processing_id: str):
    """Cancel a running vehicle counting process."""
    task = cancellation.get_task_status(processing_id)
    if not task:
        return {"status": "not_found", "processing_id": processing_id}
    if task.get("completed"):
        return {"status": "already_completed", "processing_id": processing_id}
    cancellation.mark_cancelled(processing_id)
    logger.warning("Cancelled processing_id=%s", processing_id)
    return {"status": "cancelled", "processing_id": processing_id}
