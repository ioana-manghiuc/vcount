"""Frame annotation and overlay rendering."""
import cv2
import numpy as np
from typing import List, Dict


class FrameAnnotator:
    """Handles drawing overlays on video frames."""
    
    @staticmethod
    def extract_color_from_argb(argb: int) -> tuple[int, int, int]:
        """
        Extract BGR color from ARGB32 integer.
        
        Args:
            argb: ARGB color as 32-bit integer
            
        Returns:
            tuple: (B, G, R) color values
        """
        b = (argb >> 0) & 0xFF
        g = (argb >> 8) & 0xFF
        r = (argb >> 16) & 0xFF
        return (b, g, r)
    
    @staticmethod
    def draw_direction_lines(
        overlay: np.ndarray,
        direction: dict,
        direction_data: dict
    ) -> None:
        """
        Draw entry and exit lines for a direction.
        
        Args:
            overlay: Frame to draw on
            direction: Direction configuration from counter
            direction_data: Original direction data with color info
        """
        # Extract color
        if direction_data and 'color' in direction_data:
            color_bgr = FrameAnnotator.extract_color_from_argb(direction_data['color'])
        else:
            color_bgr = (255, 255, 255)
        
        # Draw entry line
        ex1 = int(direction['entry_line']['x1'])
        ey1 = int(direction['entry_line']['y1'])
        ex2 = int(direction['entry_line']['x2'])
        ey2 = int(direction['entry_line']['y2'])
        cv2.line(overlay, (ex1, ey1), (ex2, ey2), color_bgr, 3)
        
        mid_x, mid_y = (ex1 + ex2) // 2, (ey1 + ey2) // 2
        cv2.putText(
            overlay, "ENTRY", (mid_x - 30, mid_y - 8),
            cv2.FONT_HERSHEY_SIMPLEX, 0.5, color_bgr, 2, cv2.LINE_AA
        )
        
        # Draw exit line
        x1 = int(direction['exit_line']['x1'])
        y1 = int(direction['exit_line']['y1'])
        x2 = int(direction['exit_line']['x2'])
        y2 = int(direction['exit_line']['y2'])
        cv2.line(overlay, (x1, y1), (x2, y2), color_bgr, 2, cv2.LINE_4)
        
        mid_x, mid_y = (x1 + x2) // 2, (y1 + y2) // 2
        cv2.putText(
            overlay, "EXIT", (mid_x - 25, mid_y + 20),
            cv2.FONT_HERSHEY_SIMPLEX, 0.5, color_bgr, 2, cv2.LINE_AA
        )
    
    @staticmethod
    def draw_detections(overlay: np.ndarray, detections: List[dict]) -> None:
        """
        Draw bounding boxes and IDs for detected objects.
        
        Args:
            overlay: Frame to draw on
            detections: List of detection dictionaries
        """
        for det in detections:
            x1, y1, x2, y2 = det['bbox']
            cx, cy = int(det['cx']), int(det['cy'])
            
            cv2.rectangle(overlay, (x1, y1), (x2, y2), (255, 255, 0), 2)
            cv2.circle(overlay, (cx, cy), 3, (0, 0, 255), -1)
            cv2.putText(
                overlay,
                f"ID {det['track_id']} cls {det['class_id']}",
                (x1, y1 - 8),
                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 0), 1, cv2.LINE_AA
            )
    
    @staticmethod
    def draw_counts(
        overlay: np.ndarray,
        directions: List[dict],
        counts: Dict[str, dict],
        directions_data: List[dict]
    ) -> None:
        """
        Draw vehicle count labels for each direction.
        
        Args:
            overlay: Frame to draw on
            directions: List of direction configurations
            counts: Count data by direction ID
            directions_data: Original direction data with color info
        """
        y_offset = 25
        
        for direction in directions:
            dir_id = direction['id']
            
            # Extract color
            dir_data = next(
                (dd for dd in directions_data if dd['id'] == dir_id), None
            )
            if dir_data and 'color' in dir_data:
                text_color = FrameAnnotator.extract_color_from_argb(dir_data['color'])
            else:
                text_color = (50, 255, 50)
            
            # Build label
            label = (
                f"{direction['from']} -> {direction['to']}: "
                f"B:{counts[dir_id]['bikes']} "
                f"C:{counts[dir_id]['cars']} "
                f"Bu:{counts[dir_id]['buses']} "
                f"T:{counts[dir_id]['trucks']}"
            )
            
            # Draw background
            (text_w, text_h), _ = cv2.getTextSize(
                label, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 2
            )
            cv2.rectangle(
                overlay,
                (15, y_offset - text_h - 5),
                (25 + text_w, y_offset + 5),
                (0, 0, 0), -1
            )
            cv2.rectangle(
                overlay,
                (15, y_offset - text_h - 5),
                (25 + text_w, y_offset + 5),
                text_color, 2
            )
            
            # Draw text
            cv2.putText(
                overlay, label, (20, y_offset),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, text_color, 2, cv2.LINE_AA
            )
            y_offset += 35
    
    @classmethod
    def annotate_frame(
        cls,
        frame: np.ndarray,
        detections: List[dict],
        directions: List[dict],
        counts: Dict[str, dict],
        directions_data: List[dict]
    ) -> np.ndarray:
        """
        Create fully annotated frame with all overlays.
        
        Args:
            frame: Original video frame
            detections: Current frame detections
            directions: Direction configurations
            counts: Vehicle counts by direction
            directions_data: Original direction data
            
        Returns:
            Annotated frame
        """
        overlay = frame.copy()
        
        # Draw direction lines
        for direction in directions:
            dir_data = next(
                (dd for dd in directions_data if dd['id'] == direction['id']), None
            )
            cls.draw_direction_lines(overlay, direction, dir_data)
        
        # Draw detections
        cls.draw_detections(overlay, detections)
        
        # Draw counts
        cls.draw_counts(overlay, directions, counts, directions_data)
        
        return overlay
