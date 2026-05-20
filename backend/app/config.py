import os
from pydantic_settings import BaseSettings
from pydantic import model_validator

class Settings(BaseSettings):
    ENV: str = os.getenv("ENV", "development")
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql://postgres:password@localhost:5432/expensetracker")
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-super-secret-key-change-in-production")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))

    class Config:
        env_file = ".env"

    @model_validator(mode="after")
    def validate_production_keys(self):
        if self.ENV == "production" and self.SECRET_KEY == "your-super-secret-key-change-in-production":
            raise ValueError("SECRET_KEY must be changed from the default development key when ENV=production.")
        return self

settings = Settings()

