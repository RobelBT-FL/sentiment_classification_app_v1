from fastapi import APIRouter, Depends
from app.models.sentiment import SentimentRequest, SentimentResponse
from app.api.deps.model_loader import get_model
from app.api.deps.services import get_sentiment_service

router = APIRouter()

@router.post(
    "/predict",
    response_model=SentimentResponse,
    summary="Predict Sentiment"
)
def predict_sentiment(
    request: SentimentRequest,
    model = Depends(get_model),
    service = Depends(get_sentiment_service)
):
    """
    Predict the sentiment of a given text.
    """
    result = service.predict(request.text, model)
    return SentimentResponse(label=result.label, score=result.score)
