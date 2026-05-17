from fastapi import FastAPI
from app.database import engine, Base, SessionLocal
from app.middleware.auth_middleware import add_cors_middleware
from app.routers import auth, expenses, users, dashboard
from app.seed import seed_database

app = FastAPI(title="Expense Tracker API")

add_cors_middleware(app)

app.include_router(auth.router)
app.include_router(expenses.router)
app.include_router(users.router)
app.include_router(dashboard.router)

@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed_database(db)
    finally:
        db.close()

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Welcome to the Expense Tracker API"}
