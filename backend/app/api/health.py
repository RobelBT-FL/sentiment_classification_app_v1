from fastapi import APIRouter

router = APIRouter()

@router.get("/", summary="Health Check")
def health_check():
    return {"status": "ok"}

