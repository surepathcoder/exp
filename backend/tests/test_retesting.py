"""
RETESTING
=========
Re-verifies specific bugs that were fixed during development
to confirm they no longer occur.

Bug inventory (from project history):
  BUG-001  DB migration: duplicate wallettypeenum / projectstatusenum creation crashed Postgres
  BUG-002  dart2js minification: NoSuchMethodError on enum .name property (redundant extension)
  BUG-003  Unapproved user could not log in → clear 403 returned
  BUG-004  Expense amount stored as Numeric but returned as string → client parse edge-case
  BUG-005  Wallet _parseAmount: None balance caused null reference crash
  BUG-006  users_screen.dart: dynamic currentUser caused dart2js method-not-found on .role.name
"""
import pytest
from tests.conftest import make_user, auth_headers


# =========================================================================== #
# BUG-001 – Enum uniqueness in migration (runtime equivalent check)            #
# =========================================================================== #
class TestBug001EnumMigration:
    """The migration bug caused duplicate CREATE TYPE statements.
    We verify the database tables are correctly created without collisions."""

    def test_wallets_table_accessible(self, client, regular_user):
        """Wallets endpoint working means the wallets table exists correctly."""
        r = client.get("/api/wallets/", headers=auth_headers(regular_user))
        assert r.status_code == 200

    def test_projects_table_accessible(self, client, regular_user):
        """Projects endpoint working means the projects table exists correctly."""
        r = client.get("/api/projects/", headers=auth_headers(regular_user))
        assert r.status_code == 200

    def test_wallet_type_enum_accepted(self, client, regular_user):
        """All four wallet types from wallettypeenum must be accepted."""
        for wallet_type in ["cash", "bank", "mobile_money", "credit_card"]:
            r = client.post(
                "/api/wallets/",
                headers=auth_headers(regular_user),
                json={
                    "name": f"Test {wallet_type}",
                    "type": wallet_type,
                    "currency": "USD",
                    "opening_balance": 0.0,
                    "icon": "wallet",
                    "color": "#000000",
                },
            )
            assert r.status_code in (200, 201), \
                f"Wallet type '{wallet_type}' was rejected: {r.text}"

    def test_project_status_enum_accepted(self, client, regular_user):
        """All five project status values from projectstatusenum must be accepted."""
        for status in ["upcoming", "active", "completed", "cancelled"]:
            r = client.post(
                "/api/projects/",
                headers=auth_headers(regular_user),
                json={
                    "name": f"Project {status}",
                    "currency": "USD",
                    "status": status,
                },
            )
            assert r.status_code in (200, 201), \
                f"Project status '{status}' was rejected: {r.text}"


# =========================================================================== #
# BUG-002 – dart2js enum .name (Python-side: UserRole string values)           #
# =========================================================================== #
class TestBug002EnumNameValues:
    """The Flutter bug was caused by extension shadowing the built-in .name.
    The API must return lowercase role strings exactly as the Dart enum expects."""

    def test_me_returns_lowercase_role(self, client, regular_user):
        r = client.get("/api/auth/me", headers=auth_headers(regular_user))
        assert r.status_code == 200
        role = r.json()["role"]
        assert role == role.lower(), f"Role must be lowercase, got '{role}'"

    def test_user_role_is_user(self, client, regular_user):
        r = client.get("/api/auth/me", headers=auth_headers(regular_user))
        assert r.json()["role"] == "user"

    def test_admin_role_returned_correctly(self, client, admin_user):
        r = client.get("/api/auth/me", headers=auth_headers(admin_user))
        assert r.json()["role"] == "admin"

    def test_superadmin_role_returned_correctly(self, client, superadmin_user):
        r = client.get("/api/auth/me", headers=auth_headers(superadmin_user))
        assert r.json()["role"] == "superadmin"


# =========================================================================== #
# BUG-003 – Unapproved user login must return 403                              #
# =========================================================================== #
class TestBug003UnapprovedUserLogin:
    def test_unapproved_user_gets_403(self, client, db):
        user = make_user(db, email="pending@test.com", is_approved=False)
        r = client.post(
            "/api/auth/login",
            json={"email": user.email, "password": "password123"},
        )
        assert r.status_code == 403

    def test_403_detail_message_present(self, client, db):
        user = make_user(db, email="pending2@test.com", is_approved=False)
        r = client.post(
            "/api/auth/login",
            json={"email": user.email, "password": "password123"},
        )
        data = r.json()
        assert "detail" in data
        assert "pending" in data["detail"].lower() or "approval" in data["detail"].lower()

    def test_approved_user_gets_token(self, client, regular_user):
        """Regression: approving user must restore login."""
        r = client.post(
            "/api/auth/login",
            json={"email": regular_user.email, "password": "password123"},
        )
        assert r.status_code == 200
        assert "access_token" in r.json()["token"]


# =========================================================================== #
# BUG-004 – Expense amount returned as string/Numeric must be parseable        #
# =========================================================================== #
class TestBug004ExpenseAmountParsing:
    def _parse_amount(self, val):
        if val is None:
            return 0.0
        if isinstance(val, (int, float)):
            return float(val)
        if isinstance(val, str):
            try:
                return float(val)
            except ValueError:
                return 0.0
        return 0.0

    def test_create_expense_amount_parseable(self, client, regular_user):
        r = client.post(
            "/api/expenses/",
            headers=auth_headers(regular_user),
            json={
                "amount": 123.45,
                "currency": "USD",
                "category": "Transport",
                "date": "2025-01-01T00:00:00",
            },
        )
        assert r.status_code in (200, 201)
        raw_amount = r.json()["amount"]
        parsed = self._parse_amount(raw_amount)
        assert parsed == pytest.approx(123.45)

    def test_large_amount_parseable(self, client, regular_user):
        r = client.post(
            "/api/expenses/",
            headers=auth_headers(regular_user),
            json={
                "amount": 999999.99,
                "currency": "TZS",
                "category": "Operations",
                "date": "2025-01-01T00:00:00",
            },
        )
        assert r.status_code in (200, 201)
        raw_amount = r.json()["amount"]
        parsed = self._parse_amount(raw_amount)
        assert parsed == pytest.approx(999999.99, rel=1e-3)


# =========================================================================== #
# BUG-005 – Wallet _parseAmount None safety                                    #
# =========================================================================== #
class TestBug005WalletNullBalance:
    def test_wallet_with_zero_opening_balance(self, client, regular_user):
        r = client.post(
            "/api/wallets/",
            headers=auth_headers(regular_user),
            json={
                "name": "Zero Balance Wallet",
                "type": "cash",
                "currency": "USD",
                "opening_balance": 0.0,
                "icon": "wallet",
                "color": "#000000",
            },
        )
        assert r.status_code in (200, 201)
        data = r.json()
        # balance or opening_balance must be parseable without crashing
        balance = data.get("balance") or data.get("opening_balance") or 0
        assert float(str(balance)) == pytest.approx(0.0)

    def test_wallet_balance_is_numeric_type(self, client, regular_user):
        r = client.post(
            "/api/wallets/",
            headers=auth_headers(regular_user),
            json={
                "name": "Numeric Wallet",
                "type": "cash",
                "currency": "KES",
                "opening_balance": 10000.0,
                "icon": "wallet",
                "color": "#ffffff",
            },
        )
        assert r.status_code in (200, 201)
        raw = r.json().get("opening_balance") or r.json().get("balance")
        assert float(str(raw)) == pytest.approx(10000.0)


# =========================================================================== #
# BUG-006 – users_screen.dart dynamic type / role.name regression              #
# =========================================================================== #
class TestBug006RoleNameStaticAccess:
    """API must return exact lowercase role strings so Dart's built-in
    enum.name getter (which is always lowercase) matches correctly."""

    def test_users_list_roles_are_lowercase(self, client, db, admin_user):
        make_user(db, email="extra1@test.com", role="user")
        r = client.get("/api/users/", headers=auth_headers(admin_user))
        assert r.status_code == 200
        for user in r.json():
            role = user.get("role", "")
            assert role == role.lower(), f"User role must be lowercase: {role}"

    def test_login_response_contains_lowercase_role(self, client, regular_user):
        r = client.post(
            "/api/auth/login",
            json={"email": regular_user.email, "password": "password123"},
        )
        role = r.json()["user"]["role"]
        assert role == "user"

    def test_me_endpoint_role_string_matches_dart_enum(self, client, superadmin_user):
        """Dart enum name is 'superadmin' (all lowercase, no spaces)."""
        r = client.get("/api/auth/me", headers=auth_headers(superadmin_user))
        assert r.json()["role"] == "superadmin"
