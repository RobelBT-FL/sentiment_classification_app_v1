from app.services.sentiment_service import SentimentService
from app.services.evaluation_service import EvaluationService

def get_sentiment_service():
    return SentimentService()

def get_evaluation_service():
    return EvaluationService()
