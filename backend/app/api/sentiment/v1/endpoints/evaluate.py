from fastapi import APIRouter, Depends
from pathlib import Path

from app.models.evaluation import EvaluationRequest
from app.api.deps.services import get_evaluation_service
from app.api.deps.model_loader import get_model
from app.services.sentiment_service import SentimentService

router = APIRouter()

def resolve_dataset_path(request_path: str | None) -> str:
    """
    Universal dataset path resolver.
    Priority:
    1. Use path sent from frontend (if provided)
    2. Use Docker path (/app/data/imdb.csv)
    3. Use local path (./data/imdb.csv)
    """

    # 1. If frontend provided a path, use it
    if request_path:
        return request_path

    # 2. Docker path
    docker_path = Path("/app/data/imdb.csv")
    if docker_path.exists():
        return str(docker_path)

    # 3. Local development path
    local_path = Path("./data/imdb.csv")
    if local_path.exists():
        return str(local_path)

    # 4. Nothing found
    raise FileNotFoundError("Dataset not found in Docker or local environment.")


@router.post("/evaluate", summary="Evaluate model on IMDB dataset")
def evaluate_model(
    request: EvaluationRequest,
    model = Depends(get_model),
    service = Depends(get_evaluation_service)
):
    """
    Evaluate the model using:
    - frontend-provided dataset path (if any)
    - OR auto-detected Docker/local dataset path
    """

    sentiment_service = SentimentService()

    def predict_fn(text, model):
        result = sentiment_service.predict(text, model)
        return result.label

    # ⭐ Universal dataset path resolution
    dataset_path = resolve_dataset_path(request.dataset_path)

    result = service.evaluate(
        dataset_path=dataset_path,
        model=model,
        predict_fn=predict_fn
    )

    return result

