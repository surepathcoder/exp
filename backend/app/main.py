from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
import os
from app.database import engine, Base, SessionLocal
from app.middleware.auth_middleware import add_cors_middleware
from app.routers import (
    auth, expenses, users, dashboard, incomes, transfers,
    notifications, settings, settings_categories, settings_users,
    settings_stats, settings_audit,
)
from app.seed import seed_database
from app.config import settings as app_settings

# Create uploads directory if it doesn't exist
os.makedirs("uploads", exist_ok=True)

app = FastAPI(title="Expense Tracker API")

add_cors_middleware(app)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Existing routers
app.include_router(auth.router)
app.include_router(expenses.router)
app.include_router(users.router)
app.include_router(dashboard.router)
app.include_router(incomes.router)
app.include_router(transfers.router)
app.include_router(notifications.router)

# Settings module routers
app.include_router(settings.router)
app.include_router(settings_categories.router)
app.include_router(settings_users.router)
app.include_router(settings_stats.router)
app.include_router(settings_audit.router)


@app.on_event("startup")
def on_startup():
    if app_settings.ENV != "production":
        Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed_database(db)
    finally:
        db.close()


@app.get("/")
def read_root():
    return {"status": "ok", "message": "Welcome to the Expense Tracker API"}
