from fastapi import FastAPI, UploadFile, File
from fastapi.responses import FileResponse
import os
import cv2
from uuid import uuid4

app = FastAPI()

# folders for storage
UPLOAD_FOLDER = "videos"
FRAME_FOLDER = "frames"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(FRAME_FOLDER, exist_ok=True)


@app.post("/upload_frame")
async def upload_video_and_get_frame(video: UploadFile = File(...)):
    # Save uploaded video
    video_id = str(uuid4())
    video_path = os.path.join(UPLOAD_FOLDER, f"{video_id}_{video.filename}")
    with open(video_path, "wb") as f:
        f.write(await video.read())

    # Extract a frame using OpenCV (at 1 second)
    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    frame_number = int(fps * 1)  # 1 second
    cap.set(cv2.CAP_PROP_POS_FRAMES, frame_number)

    ret, frame = cap.read()
    if not ret:
        cap.release()
        return {"error": "Failed to read frame from video"}

    frame_path = os.path.join(FRAME_FOLDER, f"{video_id}.png")
    cv2.imwrite(frame_path, frame)
    cap.release()

    # Return URL (assuming frontend can access backend /frames endpoint)
    return {"thumbnail_url": f"/frames/{video_id}.png"}


@app.get("/frames/{filename}")
def get_frame(filename: str):
    path = os.path.join(FRAME_FOLDER, filename)
    if os.path.exists(path):
        return FileResponse(path, media_type="image/png")
    return {"error": "Frame not found"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="127.0.0.1", port=8000, reload=True)
