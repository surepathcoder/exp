from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from app.models import User, Expense, RoleEnum, CurrencyEnum, SystemSettings, Category, Project, ProjectStatusEnum
from app.auth import get_password_hash

DEFAULT_CATEGORIES_DATA = [
    {"name": "Travel", "color": "#3F51B5", "icon": "flight", "type": "expense"},
    {"name": "Worship committee", "color": "#E91E63", "icon": "church", "type": "expense"},
    {"name": "Volunteers committee", "color": "#9C27B0", "icon": "people_outline", "type": "expense"},
    {"name": "Technical committee", "color": "#673AB7", "icon": "computer", "type": "expense"},
    {"name": "Protocol committee", "color": "#009688", "icon": "security", "type": "expense"},
    {"name": "Invasion", "color": "#4CAF50", "icon": "campaign", "type": "expense"},
    {"name": "Zones", "color": "#8BC34A", "icon": "map", "type": "expense"},
    {"name": "BOA,ECC,APM", "color": "#CDDC39", "icon": "business_center", "type": "expense"},
    {"name": "Youth committee", "color": "#FFC107", "icon": "face", "type": "expense"},
    {"name": "Woman committee", "color": "#FF9800", "icon": "pregnant_woman", "type": "expense"},
    {"name": "Prayer committee", "color": "#FF5722", "icon": "volunteer_activism", "type": "expense"},
    {"name": "Church Mobilization", "color": "#795548", "icon": "groups", "type": "expense"},
    {"name": "Promo", "color": "#9E9E9E", "icon": "campaign", "type": "expense"},
    {"name": "Food & Drinks", "color": "#FF5722", "icon": "restaurant", "type": "expense"},
    {"name": "Accommodation", "color": "#00BCD4", "icon": "hotel", "type": "expense"},
    {"name": "Transfer", "color": "#607D8B", "icon": "swap_horiz", "type": "expense"},
    {"name": "Hospitality", "color": "#E91E63", "icon": "local_cafe", "type": "expense"},
    {"name": "Permits", "color": "#3F51B5", "icon": "description", "type": "expense"},
    {"name": "Appreciation", "color": "#4CAF50", "icon": "card_giftcard", "type": "expense"},
    {"name": "Internet/Phone", "color": "#9C27B0", "icon": "phone_android", "type": "expense"},
    {"name": "Print", "color": "#00BCD4", "icon": "print", "type": "expense"},
    {"name": "Committees", "color": "#673AB7", "icon": "groups", "type": "expense"},
    {"name": "Other", "color": "#9E9E9E", "icon": "more_horiz", "type": "expense"},
    {"name": "Salary", "color": "#009688", "icon": "payments", "type": "income"},
    {"name": "Donations", "color": "#4CAF50", "icon": "volunteer_activism", "type": "income"},
    {"name": "Grants", "color": "#FF9800", "icon": "monetization_on", "type": "income"},
    {"name": "Refunds", "color": "#2196F3", "icon": "settings_backup_restore", "type": "income"},
]


def seed_settings(db: Session):
    """Ensure singleton SystemSettings row exists."""
    existing = db.query(SystemSettings).filter(SystemSettings.id == 1).first()
    if not existing:
        db.add(SystemSettings(id=1))
        db.commit()
        print("  ✓ System settings seeded")


def seed_categories(db: Session):
    """Seed default categories or update existing ones with color/icon/type."""
    for i, data in enumerate(DEFAULT_CATEGORIES_DATA):
        cat = db.query(Category).filter(Category.name == data["name"]).first()
        if not cat:
            db.add(Category(
                name=data["name"],
                color=data["color"],
                icon=data["icon"],
                type=data["type"],
                sort_order=i,
                is_active=True
            ))
        else:
            # Backfill/update default values
            if cat.color == "#9E9E9E" or not cat.color:
                cat.color = data["color"]
            if not cat.icon:
                cat.icon = data["icon"]
            if cat.type != data["type"]:
                cat.type = data["type"]
    db.commit()
    print(f"  ✓ {len(DEFAULT_CATEGORIES_DATA)} categories seeded/updated")


def seed_users(db: Session):
    """Seed default users if none exist."""
    if db.query(User).first():
        return db.query(User).all()

    users_data = [
        {"name": "Harrison Kiwone", "email": "super@awoken.com", "role": RoleEnum.superadmin},
        {"name": "Admin User", "email": "admin@awoken.com", "role": RoleEnum.admin},
        {"name": "John Doe", "email": "john@example.com", "role": RoleEnum.user},
        {"name": "Jane Smith", "email": "jane@example.com", "role": RoleEnum.user},
    ]
    hashed = get_password_hash("password")
    db_users = []
    for data in users_data:
        user = User(
            name=data["name"],
            email=data["email"],
            password_hash=hashed,
            role=data["role"],
            is_approved=True,
        )
        db.add(user)
        db_users.append(user)
    db.commit()
    for u in db_users:
        db.refresh(u)
    print(f"  ✓ {len(db_users)} users seeded")
    return db_users


def seed_projects(db: Session, db_users: list) -> dict:
    """Seed default projects and return a mapping of project name -> ID."""
    existing_projects = db.query(Project).all()
    if existing_projects:
        return {p.name: p.id for p in existing_projects}

    admin_id = db_users[1].id if len(db_users) > 1 else None
    
    projects_data = [
        {"name": "Operations", "description": "Standard business operations and logistics", "budget": 20000.0, "currency": CurrencyEnum.USD, "status": ProjectStatusEnum.active, "user_id": admin_id},
        {"name": "Missions", "description": "International and local outreach missions", "budget": 15000.0, "currency": CurrencyEnum.USD, "status": ProjectStatusEnum.active, "user_id": admin_id},
        {"name": "Worship Night", "description": "Annual community gathering and praise event", "budget": 5000.0, "currency": CurrencyEnum.USD, "status": ProjectStatusEnum.upcoming, "user_id": admin_id},
        {"name": "Youth Camp", "description": "Youth training and sports summer workshop", "budget": 10000.0, "currency": CurrencyEnum.USD, "status": ProjectStatusEnum.active, "user_id": admin_id},
    ]
    
    mapping = {}
    for p_data in projects_data:
        proj = Project(**p_data)
        db.add(proj)
        db.commit()
        db.refresh(proj)
        mapping[proj.name] = proj.id
        
    print(f"  ✓ {len(projects_data)} projects seeded")
    return mapping


def seed_expenses(db: Session, db_users: list, project_mapping: dict):
    """Seed sample expenses."""
    if not db_users or db.query(Expense).first():
        return
    admin_id = db_users[1].id
    john_id = db_users[2].id
    now = datetime.utcnow()

    expenses = [
        {"amount": 2745.0, "currency": CurrencyEnum.USD, "category": "Travel", "date": now - timedelta(days=1), "user_id": admin_id, "is_self_receipt": False, "vendor": "Turkish Airlines", "project_id": project_mapping.get("Missions")},
        {"amount": 1494.0, "currency": CurrencyEnum.USD, "category": "Print", "date": now - timedelta(days=2), "user_id": admin_id, "is_self_receipt": True, "vendor": "City Printers", "project_id": project_mapping.get("Operations")},
        {"amount": 2344.0, "currency": CurrencyEnum.USD, "category": "Accommodation", "date": now - timedelta(days=3), "user_id": admin_id, "is_self_receipt": False, "vendor": "Hilton Hotel", "project_id": project_mapping.get("Missions")},
        {"amount": 1000.0, "currency": CurrencyEnum.USD, "category": "Transfer", "date": now - timedelta(days=4), "user_id": john_id, "is_self_receipt": False, "vendor": "Bank of America", "project_id": project_mapping.get("Operations")},
        {"amount": 757.0, "currency": CurrencyEnum.USD, "category": "Hospitality", "date": now - timedelta(days=5), "user_id": admin_id, "is_self_receipt": True, "vendor": "Starbucks", "project_id": project_mapping.get("Worship Night")},
        {"amount": 273.0, "currency": CurrencyEnum.USD, "category": "Food & Drinks", "date": now - timedelta(days=6), "user_id": john_id, "is_self_receipt": False, "vendor": "Burger King", "project_id": project_mapping.get("Youth Camp")},
        {"amount": 406.0, "currency": CurrencyEnum.USD, "category": "BOA,ECC,APM", "date": now - timedelta(days=7), "user_id": admin_id, "is_self_receipt": False, "vendor": "Auditing Partners", "project_id": project_mapping.get("Operations")},
        {"amount": 10000.0, "currency": CurrencyEnum.USD, "category": "Committees", "date": now - timedelta(days=8), "user_id": admin_id, "is_self_receipt": False, "vendor": "Internal Audit", "project_id": project_mapping.get("Operations")},
        {"amount": 610.0, "currency": CurrencyEnum.USD, "category": "Appreciation", "date": now - timedelta(days=9), "user_id": john_id, "is_self_receipt": True, "vendor": "Gift Cards Inc", "project_id": project_mapping.get("Youth Camp")},
        {"amount": 35.0, "currency": CurrencyEnum.USD, "category": "Permits", "date": now - timedelta(days=10), "user_id": john_id, "is_self_receipt": False, "vendor": "City Council", "project_id": project_mapping.get("Operations")},
        {"amount": 80.0, "currency": CurrencyEnum.USD, "category": "Internet/Phone", "date": now - timedelta(days=11), "user_id": admin_id, "is_self_receipt": False, "vendor": "Vodacom", "project_id": project_mapping.get("Operations")},
        {"amount": 50.0, "currency": CurrencyEnum.USD, "category": "Other", "date": now - timedelta(days=12), "user_id": john_id, "is_self_receipt": False, "vendor": "Corner Store", "project_id": project_mapping.get("Worship Night")},
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
    project_mapping = seed_projects(db, db_users)
    seed_expenses(db, db_users, project_mapping)
    print("Database seeding complete.")
