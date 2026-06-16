from datetime import datetime
from typing import Dict

processing_tasks: Dict[str, dict] = {}


def register_task(processing_id: str, total_frames: int = 0) -> None:
    """Register a new processing task."""
    processing_tasks[processing_id] = {
        "cancelled": False,
        "completed": False,
        "frames_processed": 0,
        "total_frames": total_frames,
    }


def is_cancelled(processing_id: str) -> bool:
    return processing_tasks.get(processing_id, {}).get("cancelled", False)


def mark_cancelled(processing_id: str) -> None:
    if processing_id in processing_tasks:
        processing_tasks[processing_id]["cancelled"] = True


def update_progress(processing_id: str, frames_processed: int) -> None:
    """Update the number of frames processed so far."""
    if processing_id in processing_tasks:
        processing_tasks[processing_id]["frames_processed"] = frames_processed


def get_progress(processing_id: str) -> dict:
    """
    Return current progress as a dict with:
      frames_processed, total_frames, percent (0-100), completed, cancelled.
    Returns an empty dict if the id is unknown.
    """
    task = processing_tasks.get(processing_id)
    if task is None:
        return {}

    total = task.get("total_frames", 0)
    done = task.get("frames_processed", 0)
    percent = round((done / total) * 100, 1) if total > 0 else 0.0

    return {
        "frames_processed": done,
        "total_frames": total,
        "percent": percent,
        "completed": task.get("completed", False),
        "cancelled": task.get("cancelled", False),
        "error": task.get("error"),
    }


def mark_completed(processing_id: str, error: str = None) -> None:
    if processing_id in processing_tasks:
        processing_tasks[processing_id]["completed"] = True
        processing_tasks[processing_id]["completed_time"] = datetime.now()
        if error:
            processing_tasks[processing_id]["error"] = error


def get_task_status(processing_id: str) -> dict:
    return processing_tasks.get(processing_id, {})
