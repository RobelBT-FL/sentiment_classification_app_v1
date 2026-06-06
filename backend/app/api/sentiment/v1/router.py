from fastapi import APIRouter
from app.api.sentiment.v1.endpoints.sentiment import router as sentiment_router
from app.api.sentiment.v1.endpoints.evaluate import router as evaluate_router

api_router = APIRouter(tags=["sentiment"])

api_router.include_router(sentiment_router)
api_router.include_router(evaluate_router)
