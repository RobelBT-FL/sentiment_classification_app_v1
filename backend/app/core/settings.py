from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "Sentiment Classification API"
    debug: bool = True

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()

