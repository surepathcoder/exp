"""
Test Configuration & Shared Fixtures
=====================================
Strategy:
  - Set DATABASE_URL env var BEFORE any app imports so Settings picks it up
  - Then directly re-wire app.database.engine and SessionLocal to the SQLite engine
  - Override the get_db dependency in every TestClient call
"""
import os
import sys

# ── Force UTF-8 output on Windows (fixes ✓ in seed.py crashing on cp1252) ──
os.environ["PYTHONIOENCODING"] = "utf-8"
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

# ── Must happen BEFORE any app module is imported ──────────────────────────
os.environ["DATABASE_URL"] = "sqlite:///./test_temp.db"
os.environ["SECRET_KEY"]   = "test-secret-key-for-testing-only"
os.environ["ALGORITHM"]    = "HS256"
os.environ["ACCESS_TOKEN_EXPIRE_MINUTES"] = "1440"

# Clear any cached app modules so env vars are picked up fresh
for mod_name in list(sys.modules.keys()):
    if mod_name.startswith("app"):
        del sys.modules[mod_name]
# --------------------------------------------------------------------------

import pytest
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient

# Now import app – it will read the patched env var
import app.database as _db_module
from app.database import Base, get_db
from app.main import app
from app.models import User, RoleEnum
from app.auth import get_password_hash, create_access_token

# --------------------------------------------------------------------------
# Build a SQLite engine and wire it into app.database so all models use it
# --------------------------------------------------------------------------
TEST_DB_URL = "sqlite:///./test_temp.db"

_test_engine = create_engine(
    TEST_DB_URL,
    connect_args={"check_same_thread": False},
)

@event.listens_for(_test_engine, "connect")
def _fk_pragma(dbapi_conn, _):
    cur = dbapi_conn.cursor()
    cur.execute("PRAGMA foreign_keys=ON")
    cur.close()

_TestSession = sessionmaker(autocommit=False, autoflush=False, bind=_test_engine)

# Patch the global engine/session that the routers import
_db_module.engine = _test_engine
_db_module.SessionLocal = _TestSession


# --------------------------------------------------------------------------
# Fixtures
# --------------------------------------------------------------------------

@pytest.fixture(scope="session", autouse=True)
def setup_database():
    Base.metadata.create_all(bind=_test_engine)
    yield
    Base.metadata.drop_all(bind=_test_engine)
    if os.path.exists("test_temp.db"):
        try:
            os.remove("test_temp.db")
        except Exception:
            pass


@pytest.fixture()
def db(setup_database):
    """Isolated per-test DB session using savepoints (nested transaction)."""
    conn = _test_engine.connect()
    trans = conn.begin()
    session = _TestSession(bind=conn)
    try:
        yield session
    finally:
        session.close()
        trans.rollback()
        conn.close()


@pytest.fixture()
def client(db):
    def _override():
        try:
            yield db
        finally:
            pass

    app.dependency_overrides[get_db] = _override
    with TestClient(app, raise_server_exceptions=False) as c:
        yield c
    app.dependency_overrides.clear()


# --------------------------------------------------------------------------
# Seed helpers
# --------------------------------------------------------------------------

def make_user(db, name="Test User", email="test@example.com",
              password="password123", role=RoleEnum.user, is_approved=True):
    user = User(
        name=name,
        email=email,
        password_hash=get_password_hash(password),
        role=role,
        is_approved=is_approved,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def auth_headers(user: User) -> dict:
    token = create_access_token(data={"sub": user.email})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def regular_user(db):
    return make_user(db)

@pytest.fixture()
def admin_user(db):
    return make_user(db, name="Admin", email="admin@example.com",
                     role=RoleEnum.admin)

@pytest.fixture()
def superadmin_user(db):
    return make_user(db, name="SuperAdmin", email="super@example.com",
                     role=RoleEnum.superadmin)

@pytest.fixture()
def user_headers(regular_user):
    return auth_headers(regular_user)

@pytest.fixture()
def admin_headers(admin_user):
    return auth_headers(admin_user)

@pytest.fixture()
def superadmin_headers(superadmin_user):
    return auth_headers(superadmin_user)
