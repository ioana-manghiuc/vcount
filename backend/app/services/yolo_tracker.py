from ultralytics import YOLO
import cv2
from typing import Generator, List, Dict, Tuple
import logging

logger = logging.getLogger("yolo_tracker")

class YOLOVehicleTracker:
    """YOLO-based vehicle detection and tracking."""
    
    def __init__(self, model_path: str, conf: float = 0.45, imgsz: int = 640, device: str = 'cpu'):
        """
        Args:
            model_path: Path to YOLO model weights
            conf: Confidence threshold
            imgsz: Input image size
            device: 'cpu' or 'cuda'
        """
        self.model = YOLO(model_path)
        self.conf = conf
        self.imgsz = imgsz
        self.device = device
        
        self.tracker_params = {
            'max_age': 120,        
            'min_hits': 1,          
            'iou_threshold': 0.05,  
            'max_det': 300,         
        }
        
        logger.info(f"YOLO model loaded: {model_path}, device={device}, conf={conf}")
        logger.info(f"Tracker parameters: {self.tracker_params}")
    
    def track_video(self, video_path: str) -> Generator[Tuple[int, List[Dict]], None, None]:
        """
        Track vehicles in video frame by frame.
        
        Args:
            video_path: Path to video file
            
        Yields:
            Tuple of (frame_index, detections, frame)
            Each detection: {track_id: int, cx: float, cy: float, class_id: int, bbox: tuple}
        """
        cap = cv2.VideoCapture(video_path)
        
        if not cap.isOpened():
            raise RuntimeError(f"Cannot open video: {video_path}")
        
        frame_idx = 0
        
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            results = self.model.track(
                frame,
                persist=True,
                conf=max(0.15, self.conf - 0.25),  
                imgsz=self.imgsz,
                device=self.device,
                verbose=False,
                max_det=self.tracker_params['max_det'],
                tracker='bytetrack.yaml', 
            )
            
            detections = []
            
            if results and results[0].boxes is not None and results[0].boxes.id is not None:
                boxes = results[0].boxes.xyxy.cpu().numpy()
                track_ids = results[0].boxes.id.int().cpu().tolist()
                class_ids = results[0].boxes.cls.int().cpu().tolist()
                confidences = results[0].boxes.conf.cpu().numpy()
                
                for box, track_id, class_id, conf in zip(boxes, track_ids, class_ids, confidences):
                    x1, y1, x2, y2 = box
                    cx = (x1 + x2) / 2
                    cy = (y1 + y2) / 2
                    
                    detections.append({
                        'track_id': track_id,
                        'cx': cx,
                        'cy': cy,
                        'class_id': class_id,
                        'bbox': (int(x1), int(y1), int(x2), int(y2)),
                        'confidence': float(conf),
                    })
            
            yield frame_idx, detections, frame
            frame_idx += 1
        
        cap.release()
        logger.info(f"Video processing complete: {frame_idx} frames")
