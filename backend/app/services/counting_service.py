import os
import cv2
import torch
import logging
from pathlib import Path
from uuid import uuid4
from datetime import datetime

from app.config.model_config import ModelConfig
from app.services.vehicle_counter import VehicleCounter
from app.services.yolo_tracker import YOLOVehicleTracker
from app.services.video_processor import VideoProcessor
from app.utils import cancellation

logger = logging.getLogger("app")

RESULTS_FOLDER = Path("results")
RESULTS_FOLDER.mkdir(exist_ok=True)


def process_video(
    *,
    video_path: str,
    original_filename: str,
    directions_data: list,
    model_name: str,
    processing_id: str,
    annotated_filename_prefix: str = "annotated",
) -> dict:
    """
    Run detection + counting on one video file.

    Returns a result dict:
    {
        "status": "ok" | "cancelled",
        "results": { <counts> },           # empty on cancel
        "metadata": { <per-video fields> } # empty on cancel
    }

    Raises on hard errors (bad video file, model failure, etc.) so the
    caller can wrap in try/except and decide how to handle.
    """
    logger.info("process_video: %s (id=%s)", original_filename, processing_id)

    cap = cv2.VideoCapture(video_path)
    ret, frame = cap.read()
    if not ret:
        raise RuntimeError(f"Cannot read video: {video_path}")
    h, w = frame.shape[:2]
    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    cap.release()

    logger.info("Video %s: %dx%d, %.1f fps, %d frames",
                original_filename, w, h, fps, total_frames)

    device = "cuda" if torch.cuda.is_available() else "cpu"
    model_path = ModelConfig.resolve_model_path(model_name)

    tracker = YOLOVehicleTracker(
        model_path=model_path,
        conf=0.45,
        imgsz=640,
        device=device,
    )

    counter = VehicleCounter(
        directions=directions_data,
        frame_w=w,
        frame_h=h,
    )

    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    annotated_filename = (
        f"{annotated_filename_prefix}"
        f"_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        f"_{uuid4().hex[:8]}.mp4"
    )
    annotated_path = os.path.join(RESULTS_FOLDER, annotated_filename)
    writer = cv2.VideoWriter(annotated_path, fourcc, fps, (w, h))

    cancellation.update_progress(processing_id, 0)


    start_time = datetime.now()

    processor = VideoProcessor(
        tracker=tracker,
        counter=counter,
        directions_data=directions_data,
        writer=writer,
        video_path=video_path,
        processing_id=processing_id,
        total_frames=total_frames,
    )
    frame_count = processor.process_frames()

    end_time = datetime.now()
    processing_time = (end_time - start_time).total_seconds()
    writer.release()


    if cancellation.is_cancelled(processing_id):
        if os.path.exists(annotated_path):
            os.remove(annotated_path)
            logger.info("Deleted annotated video after cancel: %s", annotated_path)
        return {"status": "cancelled", "results": {}, "metadata": {}}


    results = counter.get_results()
    logger.info("process_video done: %d frames in %.2fs", frame_count, processing_time)

    return {
        "status": "ok",
        "results": results,
        "metadata": {
            "video_file": original_filename,
            "start_time": start_time.isoformat(),
            "end_time": end_time.isoformat(),
            "processing_time_seconds": round(processing_time, 2),
            "total_frames_processed": frame_count,
            "video_dimensions": {"width": w, "height": h},
            "annotated_video": f"/results/{annotated_filename}",
            "input_fps": fps,
        },
    }
