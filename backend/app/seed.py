from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from app.models import User, Expense, RoleEnum, CurrencyEnum, SystemSettings, Category
from app.auth import get_password_hash

# Default categories matching the original hardcoded constants
DEFAULT_CATEGORIES = [
    "Travel", "Worship committee", "Volunteers committee", "Technical committee",
    "Protocol committee", "Invasion", "Zones", "BOA,ECC,APM", "Youth committee",
    "Woman committee", "Prayer committee", "Church Mobilization", "Promo",
    "Food & Drinks", "Accommodation", "Transfer", "Hospitality", "Permits",
    "Appreciation", "Internet/Phone", "Print", "Committees", "Other",
]


def seed_settings(db: Session):
    """Ensure singleton SystemSettings row exists."""
    existing = db.query(SystemSettings).filter(SystemSettings.id == 1).first()
    if not existing:
        db.add(SystemSettings(id=1))
        db.commit()
        print("  ✓ System settings seeded")


def seed_categories(db: Session):
    """Seed default categories if none exist."""
    if db.query(Category).first():
        return
    for i, name in enumerate(DEFAULT_CATEGORIES):
        db.add(Category(name=name, sort_order=i, is_active=True))
    db.commit()
    print(f"  ✓ {len(DEFAULT_CATEGORIES)} categories seeded")


def seed_users(db: Session):
    """Seed default users if none exist."""
    if db.query(User).first():
        return

    users_data = [
        {"name": "Harrison Kiwone", "email": "super@awoken.com", "role": RoleEnum.superadmin},
        {"name": "Admin User", "email": "admin@awoken.com", "role": RoleEnum.admin},
        {"name": "John Doe", "email": "john@example.com", "role": RoleEnum.user},
        {"name": "Jane Smith", "email": "jane@example.com", "role": RoleEnum.user},
    ]
    hashed = get_password_hash("password")
    db_users = []
    for data in users_data:
        user = User(name=data["name"], email=data["email"], password_hash=hashed, role=data["role"])
        db.add(user)
        db_users.append(user)
    db.commit()
    for u in db_users:
        db.refresh(u)
    print(f"  ✓ {len(db_users)} users seeded")
    return db_users


def seed_expenses(db: Session, db_users: list):
    """Seed sample expenses."""
    if not db_users or db.query(Expense).first():
        return
    admin_id = db_users[1].id
    john_id = db_users[2].id
    now = datetime.utcnow()

    expenses = [
        {"amount": 2745.0, "currency": CurrencyEnum.USD, "category": "Travel", "date": now - timedelta(days=1), "user_id": admin_id, "is_self_receipt": False},
        {"amount": 1494.0, "currency": CurrencyEnum.USD, "category": "Print", "date": now - timedelta(days=2), "user_id": admin_id, "is_self_receipt": True},
        {"amount": 2344.0, "currency": CurrencyEnum.USD, "category": "Accommodation", "date": now - timedelta(days=3), "user_id": admin_id, "is_self_receipt": False},
        {"amount": 1000.0, "currency": CurrencyEnum.USD, "category": "Transfer", "date": now - timedelta(days=4), "user_id": john_id, "is_self_receipt": False},
        {"amount": 757.0, "currency": CurrencyEnum.USD, "category": "Hospitality", "date": now - timedelta(days=5), "user_id": admin_id, "is_self_receipt": True},
        {"amount": 273.0, "currency": CurrencyEnum.USD, "category": "Food & Drinks", "date": now - timedelta(days=6), "user_id": john_id, "is_self_receipt": False},
        {"amount": 406.0, "currency": CurrencyEnum.USD, "category": "BOA,ECC,APM", "date": now - timedelta(days=7), "user_id": admin_id, "is_self_receipt": False},
        {"amount": 10000.0, "currency": CurrencyEnum.USD, "category": "Committees", "date": now - timedelta(days=8), "user_id": admin_id, "is_self_receipt": False},
        {"amount": 610.0, "currency": CurrencyEnum.USD, "category": "Appreciation", "date": now - timedelta(days=9), "user_id": john_id, "is_self_receipt": True},
        {"amount": 35.0, "currency": CurrencyEnum.USD, "category": "Permits", "date": now - timedelta(days=10), "user_id": john_id, "is_self_receipt": False},
        {"amount": 80.0, "currency": CurrencyEnum.USD, "category": "Internet/Phone", "date": now - timedelta(days=11), "user_id": admin_id, "is_self_receipt": False},
        {"amount": 50.0, "currency": CurrencyEnum.USD, "category": "Other", "date": now - timedelta(days=12), "user_id": john_id, "is_self_receipt": False},
    ]
    for data in expenses:
        db.add(Expense(**data))
    db.commit()
    print(f"  ✓ {len(expenses)} expenses seeded")


def seed_database(db: Session):
    """Main seed entrypoint."""
    print("Seeding database...")
    seed_settings(db)
    seed_categories(db)
    db_users = seed_users(db)
    seed_expenses(db, db_users)
    print("Database seeding complete.")
