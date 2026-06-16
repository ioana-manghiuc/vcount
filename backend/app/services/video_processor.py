import time
import queue
import threading
import logging
from typing import List

from app.utils.cancellation import is_cancelled
from app.services.frame_annotator import FrameAnnotator
from app.utils import cancellation

logger = logging.getLogger("app")

_PROGRESS_INTERVAL = 10


class VideoProcessor:
    def __init__(
        self,
        tracker,
        counter,
        directions_data: List[dict],
        writer,
        video_path: str,
        processing_id: str,
        total_frames: int = 0,
        queue_size: int = 8,
    ):
        self.tracker = tracker
        self.counter = counter
        self.directions_data = directions_data
        self.writer = writer
        self.video_path = video_path
        self.processing_id = processing_id
        self.total_frames = total_frames
        self.annotator = FrameAnnotator()
        self._queue: queue.Queue = queue.Queue(maxsize=queue_size)
        self._detection_error: Exception | None = None



    def _detection_worker(self) -> None:
        try:
            for frame_idx, detections, frame in self.tracker.track_video(self.video_path):
                if cancellation.is_cancelled(self.processing_id):
                    logger.warning(
                        "Detection worker: cancellation detected at frame %d", frame_idx
                    )
                    break
                self._queue.put((frame_idx, detections, frame))
        except Exception as exc:
            self._detection_error = exc
            logger.exception("Detection worker failed")
        finally:
            self._queue.put(None)


    def process_frames(self) -> int:
        detection_thread = threading.Thread(
            target=self._detection_worker,
            daemon=True,
        )
        detection_thread.start()
        logger.info("Detection thread started for processing_id=%s", self.processing_id)

        frame_count = 0
        check_frequency = 0

        while True:
            item = self._queue.get()
            if item is None:
                break

            frame_idx, detections, frame = item

            if frame_idx % 5 == 0:
                check_frequency += 1
                if is_cancelled(self.processing_id):
                    logger.warning(
                        "CANCELLATION DETECTED at frame %d (check #%d)",
                        frame_idx, check_frequency,
                    )
                    break
            elif is_cancelled(self.processing_id):
                logger.warning(
                    "CANCELLATION DETECTED at frame %d (unlogged check)", frame_idx
                )
                break

            if frame_idx % 10 == 0:
                logger.info(
                    "Processing frame %d, detections: %d", frame_idx, len(detections)
                )
                
            self.counter.update(detections)
            frame_count = frame_idx

            overlay = self.annotator.annotate_frame(
                frame=frame,
                detections=detections,
                directions=self.counter.directions,
                counts=self.counter.counts,
                directions_data=self.directions_data,
            )
            self.writer.write(overlay)


            if frame_count % _PROGRESS_INTERVAL == 0:
                cancellation.update_progress(self.processing_id, frame_count)

            if frame_count % 100 == 0:
                logger.info("Processed %d frames", frame_count)

        cancellation.update_progress(self.processing_id, frame_count)

        detection_thread.join()

        if self._detection_error:
            raise self._detection_error

        logger.info(
            "Pipeline complete: %d frames for processing_id=%s",
            frame_count, self.processing_id,
        )
        return frame_count
