from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from app.models import User, Expense, RoleEnum, CurrencyEnum
from app.auth import get_password_hash

def seed_database(db: Session):
    # Check if database is already seeded
    if db.query(User).first():
        return

    print("Seeding database...")

    # Seed Users
    users_data = [
        {"name": "Harrison Kiwone", "email": "super@awoken.com", "role": RoleEnum.superadmin},
        {"name": "Admin User", "email": "admin@awoken.com", "role": RoleEnum.admin},
        {"name": "John Doe", "email": "john@example.com", "role": RoleEnum.user},
        {"name": "Jane Smith", "email": "jane@example.com", "role": RoleEnum.user},
    ]

    hashed_password = get_password_hash("password")
    db_users = []

    for user_data in users_data:
        user = User(
            name=user_data["name"],
            email=user_data["email"],
            password_hash=hashed_password,
            role=user_data["role"]
        )
        db.add(user)
        db_users.append(user)
    
    db.commit()
    for user in db_users:
        db.refresh(user)

    admin_user_id = db_users[1].id
    john_id = db_users[2].id

    # Seed Expenses based on screenshots
    now = datetime.utcnow()
    expenses_data = [
        {"amount": 2745.0, "currency": CurrencyEnum.USD, "category": "Travel", "date": now - timedelta(days=1), "user_id": admin_user_id, "is_self_receipt": False},
        {"amount": 1494.0, "currency": CurrencyEnum.USD, "category": "Print", "date": now - timedelta(days=2), "user_id": admin_user_id, "is_self_receipt": True},
        {"amount": 2344.0, "currency": CurrencyEnum.USD, "category": "Accommodation", "date": now - timedelta(days=3), "user_id": admin_user_id, "is_self_receipt": False},
        {"amount": 1000.0, "currency": CurrencyEnum.USD, "category": "Transfer", "date": now - timedelta(days=4), "user_id": john_id, "is_self_receipt": False},
        {"amount": 757.0, "currency": CurrencyEnum.USD, "category": "Hospitality", "date": now - timedelta(days=5), "user_id": admin_user_id, "is_self_receipt": True},
        {"amount": 273.0, "currency": CurrencyEnum.USD, "category": "Food & Drinks", "date": now - timedelta(days=6), "user_id": john_id, "is_self_receipt": False},
        {"amount": 406.0, "currency": CurrencyEnum.USD, "category": "BOA,ECC,APM", "date": now - timedelta(days=7), "user_id": admin_user_id, "is_self_receipt": False},
        {"amount": 10000.0, "currency": CurrencyEnum.USD, "category": "Committees", "date": now - timedelta(days=8), "user_id": admin_user_id, "is_self_receipt": False},
        {"amount": 610.0, "currency": CurrencyEnum.USD, "category": "Appreciation", "date": now - timedelta(days=9), "user_id": john_id, "is_self_receipt": True},
        {"amount": 35.0, "currency": CurrencyEnum.USD, "category": "Permits", "date": now - timedelta(days=10), "user_id": john_id, "is_self_receipt": False},
        {"amount": 80.0, "currency": CurrencyEnum.USD, "category": "Internet/Phone", "date": now - timedelta(days=11), "user_id": admin_user_id, "is_self_receipt": False},
        {"amount": 50.0, "currency": CurrencyEnum.USD, "category": "Other", "date": now - timedelta(days=12), "user_id": john_id, "is_self_receipt": False},
    ]

    for exp_data in expenses_data:
        expense = Expense(**exp_data)
        db.add(expense)

    db.commit()
    print("Database seeded successfully.")
