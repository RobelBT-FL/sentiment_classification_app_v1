from fastapi import FastAPI
from app.core.settings import settings

def create_app(lifespan=None) -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version="1.0.0",
        description="A production-ready API for text sentiment prediction and model evaluation.",
        lifespan=lifespan,
        debug=settings.debug,
    )
    return app
