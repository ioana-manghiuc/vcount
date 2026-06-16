import os
import json
import logging
import asyncio
from pathlib import Path
from uuid import uuid4
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from typing import List

from app.utils.direction_validator import validate_directions
from app.services.counting_service import process_video
from app.utils import cancellation

logger = logging.getLogger("app")

router = APIRouter(prefix="", tags=["bulk-processing"])

MAX_WORKERS = 5
bulk_executor = ThreadPoolExecutor(max_workers=MAX_WORKERS)

UPLOAD_FOLDER = Path("videos")
RESULTS_FOLDER = Path("results")
UPLOAD_FOLDER.mkdir(exist_ok=True)
RESULTS_FOLDER.mkdir(exist_ok=True)

@router.post("/count_vehicles_bulk")
async def count_vehicles_bulk(
    videos: List[UploadFile] = File(...),
    directions: str = Form(...),
    model_name: str = Form("yolo11n-best.pt"),
    intersection_name: str = Form(""),
    processing_id: str = Form(""),
):
    """
    Process multiple videos of the same intersection in parallel.

    Response schema:
    {
        "results":          { <aggregated counts across all videos> },
        "metadata":         { <global metadata> },
        "per_video_results": [ { "status", "results", "metadata" }, ... ]
    }
    """
    try:
        logger.warning("count_vehicles_bulk called — %d video(s)", len(videos))
        logger.warning("   processing_id : %s", processing_id)
        logger.warning("   model_name    : %s", model_name)
        logger.warning("   intersection  : %s", intersection_name)

        if not videos:
            raise HTTPException(400, "No videos provided")

        cancellation.register_task(processing_id)

        directions_data = json.loads(directions)
        validate_directions(directions_data)

        saved_paths: list[tuple[str, str]] = []
        for upload in videos:
            disk_path = os.path.join(UPLOAD_FOLDER, f"{uuid4()}_{upload.filename}")
            with open(disk_path, "wb") as f:
                f.write(await upload.read())
            saved_paths.append((disk_path, upload.filename or "unknown"))
            logger.info("Saved upload: %s → %s", upload.filename, disk_path)

        loop = asyncio.get_event_loop()
        per_video_results: list[dict] = [None] * len(saved_paths)

        futures = {
            bulk_executor.submit(
                process_video,
                video_path=disk_path,
                original_filename=original_name,
                directions_data=directions_data,
                model_name=model_name,
                processing_id=processing_id,
                annotated_filename_prefix=f"annotated_bulk{idx}",
            ): (idx, original_name)
            for idx, (disk_path, original_name) in enumerate(saved_paths)
        }

        def _collect_sync():
            for future in as_completed(futures):
                idx, name = futures[future]

                if cancellation.is_cancelled(processing_id):
                    logger.warning(
                        "[bulk] Cancellation detected after video %d — "
                        "cancelling remaining futures", idx
                    )
                    for f in futures:
                        f.cancel()
                    per_video_results[idx] = {
                        "status": "cancelled",
                        "video_file": name,
                        "results": {},
                        "metadata": {},
                    }
                    break

                try:
                    result = future.result()

                    if result.get("status") == "ok" and result.get("metadata"):
                        result["metadata"]["intersection_name"] = intersection_name
                        result["metadata"]["model"] = model_name
                        result["metadata"]["directions_count"] = len(directions_data)
                    per_video_results[idx] = result
                except Exception as exc:
                    logger.exception("[bulk][%d] Failed: %s — %s", idx, name, exc)
                    per_video_results[idx] = {
                        "status": "error",
                        "video_file": name,
                        "error": str(exc),
                        "results": {},
                        "metadata": {},
                    }

        await loop.run_in_executor(None, _collect_sync)

        if cancellation.is_cancelled(processing_id):
            cancellation.mark_completed(processing_id)
            return {"status": "cancelled", "processing_id": processing_id}

        aggregated: dict = {}
        for vr in per_video_results:
            if vr is None or vr.get("status") != "ok":
                continue
            for direction_key, counts in (vr.get("results") or {}).items():
                if direction_key not in aggregated:
                    aggregated[direction_key] = {}
                for vehicle_class, count in counts.items():
                    aggregated[direction_key][vehicle_class] = (
                        aggregated[direction_key].get(vehicle_class, 0) + count
                    )

        ok_results = [vr for vr in per_video_results if vr and vr.get("status") == "ok"]
        global_start = min(
            (vr["metadata"]["start_time"] for vr in ok_results),
            default=datetime.now().isoformat(),
        )
        global_end = max(
            (vr["metadata"]["end_time"] for vr in ok_results),
            default=datetime.now().isoformat(),
        )

        response_payload = {
            "results": aggregated,
            "metadata": {
                "intersection_name": intersection_name,
                "model": model_name,
                "video_count": len(videos),
                "directions_count": len(directions_data),
                "bulk": True,
                "start_time": global_start,
                "end_time": global_end,
            },
            "per_video_results": per_video_results,
        }

        result_filename = (
            f"results_bulk_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            f"_{uuid4().hex[:8]}.json"
        )
        with open(os.path.join(RESULTS_FOLDER, result_filename), "w") as f:
            json.dump(response_payload, f, indent=2)
        logger.info("Bulk results saved: %s", result_filename)

        cancellation.mark_completed(processing_id)
        return response_payload

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Bulk vehicle counting failed")
        cancellation.mark_completed(processing_id, error=str(e))
        raise HTTPException(500, f"Bulk vehicle counting failed: {str(e)}")