from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Request
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import os
import cv2
import json
import logging
from pathlib import Path
from uuid import uuid4
from dotenv import load_dotenv
from logging_config import LOGGING_CONFIG
logging.config.dictConfig(LOGGING_CONFIG)

logger = logging.getLogger("app")

load_dotenv()
app = FastAPI()

@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info("%s %s", request.method, request.url.path)
    response = await call_next(request)
    logger.info("→ %d", response.status_code)
    return response


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_FOLDER = "videos"
FRAME_FOLDER = "frames"
RESULTS_FOLDER = "results"

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(FRAME_FOLDER, exist_ok=True)
os.makedirs(RESULTS_FOLDER, exist_ok=True)

@app.post("/upload_frame")
async def upload_frame(video: UploadFile = File(...)):
    logger.info("upload_frame: filename=%s", video.filename)

    video_path = os.path.join(UPLOAD_FOLDER, video.filename)
    with open(video_path, "wb") as f:
        f.write(await video.read())

    try:
        cap = cv2.VideoCapture(video_path)
        
        if not cap.isOpened():
            raise HTTPException(400, "Failed to open video file")
        
        fps = cap.get(cv2.CAP_PROP_FPS)
        logger.info("Video FPS: %s", fps)
        
        # Extract frame at 1 second mark
        frame_index = max(0, int(fps) if fps > 0 else 30)  # Default to 30 if fps is invalid
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_index)
        
        ret, frame = cap.read()
        cap.release()

        if not ret or frame is None:
            logger.error("Failed to extract frame at index %d", frame_index)
            raise HTTPException(400, "Frame extraction failed")

        name = Path(video.filename).stem + ".png"
        path = os.path.join(FRAME_FOLDER, name)
        success = cv2.imwrite(path, frame)
        
        if not success:
            logger.error("Failed to write frame to %s", path)
            raise HTTPException(500, "Failed to save frame")

        logger.info("Thumbnail written: %s", path)
        return {"thumbnail_url": f"/frames/{name}"}
    
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Unexpected error in upload_frame: %s", str(e))
        raise HTTPException(500, f"Unexpected error: {str(e)}")


@app.get("/frames/{filename}")
def get_frame(filename: str):
    logger.info("Serving frame: %s", filename)

    path = os.path.join(FRAME_FOLDER, filename)
    if not os.path.exists(path):
        raise HTTPException(404)

    return FileResponse(path, media_type="image/png")


def validate_directions(directions):
    for d in directions:
        if "id" not in d:
            raise ValueError("Direction missing id")
        if "points" not in d or len(d["points"]) < 2:
            raise ValueError(f"Direction {d.get('id')} missing points")
        if "from" not in d or "to" not in d:
            raise ValueError(f"Direction {d.get('id')} missing from/to")


@app.post("/count_vehicles")
async def count_vehicles(
    video: UploadFile = File(...),
    directions: str = Form(...),
    model_name: str = Form("best.pt"),
):
    try:
        logger.info("count_vehicles called")

        directions_data = json.loads(directions)
        validate_directions(directions_data)

        logger.info("Model: %s", model_name)
        logger.info("Directions count: %d", len(directions_data))

        for d in directions_data:
            logger.info(
                "Direction id=%s from=%s to=%s points=%s",
                d["id"], d["from"], d["to"], d["points"]
            )

        video_path = os.path.join(UPLOAD_FOLDER, f"{uuid4()}_{video.filename}")
        with open(video_path, "wb") as f:
            f.write(await video.read())

        device = "cuda" if cv2.cuda.getCudaEnabledDeviceCount() > 0 else "cpu"
        logger.info("Device selected: %s", device)

        # yolo = VehicleCounterYOLO11(
        #     model_path=os.path.join("models", model_name),
        #     conf=0.45,
        #     imgsz=640,
        #     device=device,
        # )

        # cap = cv2.VideoCapture(video_path)
        # ret, frame = cap.read()
        # if not ret:
        #     raise RuntimeError("Cannot read video")
        # h, w = frame.shape[:2]
        # cap.release()

        # counter = VehicleCounter(lines=directions_data, frame_w=w, frame_h=h)

        # prev_positions = {}

        # for frame_idx, detections in yolo.track_video(video_path):
        #     logger.debug("Frame %d detections=%d", frame_idx, len(detections))

        #     updates = []

        #     for d in detections:
        #         tid = d["track_id"]
        #         cx, cy = d["bbox"]

        #         prev = prev_positions.get(tid)
        #         if prev:
        #             updates.append({
        #                 "id": tid,
        #                 "previous": prev,
        #                 "current": (cx / w, cy / h),
        #             })

        #         prev_positions[tid] = (cx / w, cy / h)

        #     if updates:
        #         counter.update(updates)

        # results = counter.get_results()
        # logger.info("Final results: %s", results)

        # return results

    except Exception:
        logger.exception("Vehicle counting failed")
        raise HTTPException(500, "Vehicle counting failed")