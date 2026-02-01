"""Processing cancellation tracking."""
from datetime import datetime
from typing import Dict

processing_tasks: Dict[str, dict] = {}

def register_task(processing_id: str) -> None:
    """Register a new processing task."""
    processing_tasks[processing_id] = {"cancelled": False}


def is_cancelled(processing_id: str) -> bool:
    """Check if a task has been cancelled."""
    return processing_tasks.get(processing_id, {}).get("cancelled", False)


def mark_cancelled(processing_id: str) -> None:
    """Mark a task as cancelled."""
    if processing_id in processing_tasks:
        processing_tasks[processing_id]["cancelled"] = True


def mark_completed(processing_id: str, error: str = None) -> None:
    """Mark a task as completed."""
    if processing_id in processing_tasks:
        processing_tasks[processing_id]["completed"] = True
        processing_tasks[processing_id]["completed_time"] = datetime.now()
        if error:
            processing_tasks[processing_id]["error"] = error


def get_task_status(processing_id: str) -> dict:
    """Get current task status."""
    return processing_tasks.get(processing_id, {})
