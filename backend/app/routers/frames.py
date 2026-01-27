"""Frame upload and serving endpoints."""
import os
import cv2
import logging
from pathlib import Path
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import FileResponse

logger = logging.getLogger("app")

router = APIRouter(prefix="", tags=["frames"])

UPLOAD_FOLDER = Path("videos")
FRAME_FOLDER = Path("frames")

UPLOAD_FOLDER.mkdir(exist_ok=True)
FRAME_FOLDER.mkdir(exist_ok=True)


@router.post("/upload_frame")
async def upload_frame(video: UploadFile = File(...)):
    """Upload video and extract thumbnail frame at 1 second mark."""
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
        
        frame_index = max(0, int(fps) if fps > 0 else 30)
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


@router.get("/frames/{filename}")
def get_frame(filename: str):
    """Serve extracted frame images."""
    logger.info("Serving frame: %s", filename)

    path = os.path.join(FRAME_FOLDER, filename)
    if not os.path.exists(path):
        raise HTTPException(404)

    return FileResponse(path, media_type="image/png")
