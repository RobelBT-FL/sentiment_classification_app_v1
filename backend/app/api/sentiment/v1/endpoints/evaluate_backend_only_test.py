
#REMARK - This is used when running local . Change to evaluate.py


from fastapi import APIRouter, Depends
from pathlib import Path

from app.models.evaluation import EvaluationRequest
from app.api.deps.services import get_evaluation_service
from app.api.deps.model_loader import get_model
from app.services.sentiment_service import SentimentService

router = APIRouter()

# Correct project root: parents[6]
BASE_DIR = Path(__file__).resolve().parents[6] 

# Correct dataset path
DATASET_PATH = BASE_DIR / "data" / "imdb.csv"

@router.post("/evaluate", summary="Evaluate model on IMDB dataset")
def evaluate_model(
    request: EvaluationRequest,
    model = Depends(get_model),
    service = Depends(get_evaluation_service)
):
    """
    Loads IMDB dataset internally, samples 25 positive + 25 negative,
    runs predictions, and computes accuracy, precision, recall, F1.
    """

    # Debug (optional to remove later)
    print("DEBUG DATASET_PATH:", DATASET_PATH)

    sentiment_service = SentimentService()

    def predict_fn(text, model):
        result = sentiment_service.predict(text, model)
        return result.label

    result = service.evaluate(
        dataset_path=str(DATASET_PATH),
        model=model,
        predict_fn=predict_fn
    )

    return result
