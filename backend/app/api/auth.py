from fastapi import APIRouter, HTTPException, status
from app.models.auth import LoginRequest, LoginResponse

router = APIRouter()

@router.post("/login", response_model=LoginResponse, summary="Login")
def login(request: LoginRequest):
    if not request.username or not request.password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username and password required",
        )

    token = f"token-{request.username}"
    return LoginResponse(access_token=token, token_type="bearer")

