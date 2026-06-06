import logging

logger = logging.getLogger(__name__)

class DummyModel:
    def __call__(self, prompt: str):
        text = prompt.lower()
        if "love" in text or "great" in text or "good" in text:
            return "positive"
        elif "hate" in text or "bad" in text or "terrible" in text:
            return "negative"
        else:
            return "unknown"

_model_instance = None

def get_model():
    global _model_instance
    if _model_instance is None:
        logger.info("Loading DummyModel...")
        _model_instance = DummyModel()
    return _model_instance
