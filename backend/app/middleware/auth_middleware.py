from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os

def add_cors_middleware(app: FastAPI):
    cors_origins_str = os.getenv("CORS_ORIGINS", "")
    if cors_origins_str:
        origins = [origin.strip() for origin in cors_origins_str.split(",") if origin.strip()]
    else:
        origins = ["*"]

    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

