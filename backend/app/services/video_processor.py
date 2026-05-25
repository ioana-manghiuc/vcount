import time
import queue
import threading
import logging
from typing import List

from app.utils.cancellation import is_cancelled
from app.services.frame_annotator import FrameAnnotator
from app.utils import cancellation

logger = logging.getLogger("app")

class VideoProcessor:
    def __init__(
        self,
        tracker,
        counter,
        directions_data: List[dict],
        writer,
        video_path: str,
        processing_id: str,
        queue_size: int = 8,
    ):
        """
        Args:
            tracker:          YOLOVehicleTracker instance
            counter:          VehicleCounter instance
            directions_data:  Original direction configuration
            writer:           cv2.VideoWriter instance
            video_path:       Path to input video
            processing_id:    Unique processing identifier
            queue_size:       Max frames buffered between threads (backpressure)
        """
        self.tracker = tracker
        self.counter = counter
        self.directions_data = directions_data
        self.writer = writer
        self.video_path = video_path
        self.processing_id = processing_id
        self.annotator = FrameAnnotator()
        self._queue: queue.Queue = queue.Queue(maxsize=queue_size)
        self._inference_error: Exception | None = None

    def _inference_worker(self) -> None:
        """
        Reads frames from disk and runs YOLO inference in a background thread.
        Puts (frame_idx, detections, frame) tuples into the queue.
        Always puts a None sentinel when finished so the consumer unblocks.
        """
        try:
            for frame_idx, detections, frame in self.tracker.track_video(self.video_path):
                if cancellation.is_cancelled(self.processing_id):
                    logger.warning(
                        "Inference worker: cancellation detected at frame %d", frame_idx
                    )
                    break

                self._queue.put((frame_idx, detections, frame))

        except Exception as exc:
            self._inference_error = exc
            logger.exception("Inference worker failed")

        finally:
            self._queue.put(None)

    def process_frames(self) -> int:
        """
        Start inference in a background thread, consume results in this thread.

        Returns:
            Total number of frames processed.
        """
        inference_thread = threading.Thread(
            target=self._inference_worker,
            daemon=True,
        )
        inference_thread.start()
        logger.info("Inference thread started for processing_id=%s", self.processing_id)

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
                        frame_idx,
                        check_frequency,
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

            if len(detections) > 0:
                time.sleep(0.033)

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

            if frame_count % 100 == 0:
                logger.info("Processed %d frames", frame_count)

        inference_thread.join()

        if self._inference_error:
            raise self._inference_error

        logger.info("Pipeline complete: %d frames for processing_id=%s", frame_count, self.processing_id)
        return frame_count