from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.core.config import create_app
from app.core.logging import setup_logging

from app.api import auth, health
from app.api.sentiment.v1.router import api_router as sentiment_v1_router

from app.events.startup import on_startup
from app.events.shutdown import on_shutdown


@asynccontextmanager
async def lifespan(app: FastAPI):
    await on_startup()
    yield
    await on_shutdown()


setup_logging()

# Create the app
app: FastAPI = create_app(lifespan=lifespan)

# -----------------------------
# ⭐ GLOBAL CORS MIDDLEWARE FIX
# -----------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # or ["http://localhost:3000"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# -----------------------------
# Error catcher (optional)
# -----------------------------
@app.middleware("http")
async def catch_exceptions_middleware(request, call_next):
    try:
        return await call_next(request)
    except Exception as e:
        print("🔥 INTERNAL ERROR:", e)
        import traceback
        traceback.print_exc()
        raise e


# -----------------------------
# Root endpoint
# -----------------------------
@app.get("/")
def root():
    return {"message": "Backend is running"}


# -----------------------------
# Routers
# -----------------------------
app.include_router(health.router, prefix="/health", tags=["health"])
app.include_router(auth.router, prefix="/auth", tags=["auth"])

app.include_router(
    sentiment_v1_router,
    prefix="/api/v1/sentiment",
    tags=["sentiment"],
)
