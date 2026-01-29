"""Model configuration and path resolution."""
from pathlib import Path
from fastapi import HTTPException
import logging

logger = logging.getLogger("app")
 

class ModelConfig:
    """Configuration for YOLO model paths and variants.
    """

    MODELS = {
        'yolo11s': 'yolo11s.pt',
        'yolo11m': 'yolo11m.pt',
        'yolo11l': 'yolo11l.pt'
    }

    @classmethod
    def get_models_dir(cls) -> Path:
        """Get the base models directory."""
        return Path(__file__).resolve().parent.parent / "models"

    @classmethod
    def resolve_model_path(cls, model_name: str) -> str:
        """
        Resolve model name to actual file path.
        
        Args:
            model_name: Model identifier (e.g., 'yolo11n', 'yolo11s-official')
            
        Returns:
            str: Path to model file or model name for auto-download
            
        Raises:
            HTTPException: If model is unknown or not found
        """
        models_dir = cls.get_models_dir()
        if model_name in cls.MODELS:
            filename = cls.MODELS[model_name]
            model_path = models_dir / filename
            logger.info("Using model from models directory: %s", model_path)
            
            if not model_path.exists():
                raise HTTPException(404, f"Model not found: {model_path}")
            return str(model_path)
            
        else:
            raise HTTPException(400, f"Unknown model: {model_name}")
