import logging

logger = logging.getLogger(__name__)

class SentimentService:
    def predict(self, text: str, model):
        prompt = (
            "Classify the sentiment of this text as positive or negative:\n\n"
            f"{text}\n\nAnswer:"
        )

        try:
            output = model(prompt)
        except Exception as e:
            logger.error(f"Model failed: {e}")
            return type("Result", (), {"label": "error", "score": 0.0})

        raw = str(output).lower()

        if "positive" in raw:
            label = "positive"
        elif "negative" in raw:
            label = "negative"
        else:
            label = "unknown"

        return type("Result", (), {"label": label, "score": 0.95})
