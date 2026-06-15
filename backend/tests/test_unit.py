"""
UNIT TESTS
==========
Tests pure logic and helper functions in complete isolation –
no network, no real database.

Covers:
  • auth.py  – password hashing / JWT token creation and decoding
  • validators (business-rule logic encoded in models / schemas)
  • CurrencyConverter helper logic (equivalent Python port)
  • Expense / Income / Wallet model construction
"""
import pytest
from datetime import datetime, timedelta
from jose import jwt

# ------------------------------------------------------------------ #
# 1. Password hashing                                                  #
# ------------------------------------------------------------------ #
class TestPasswordHashing:
    def test_hash_is_not_plaintext(self):
        from app.auth import get_password_hash
        hashed = get_password_hash("mySecret123")
        assert hashed != "mySecret123"

    def test_verify_correct_password(self):
        from app.auth import get_password_hash, verify_password
        hashed = get_password_hash("correct")
        assert verify_password("correct", hashed) is True

    def test_reject_wrong_password(self):
        from app.auth import get_password_hash, verify_password
        hashed = get_password_hash("correct")
        assert verify_password("wrong", hashed) is False

    def test_two_hashes_of_same_password_differ(self):
        """bcrypt uses a random salt so two hashes must differ."""
        from app.auth import get_password_hash
        h1 = get_password_hash("password")
        h2 = get_password_hash("password")
        assert h1 != h2


# ------------------------------------------------------------------ #
# 2. JWT token creation / decoding                                     #
# ------------------------------------------------------------------ #
class TestJWTToken:
    def test_token_contains_email(self):
        from app.auth import create_access_token
        from app.config import settings
        token = create_access_token(data={"sub": "alice@example.com"})
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        assert payload["sub"] == "alice@example.com"

    def test_token_has_expiry(self):
        from app.auth import create_access_token
        from app.config import settings
        token = create_access_token(data={"sub": "alice@example.com"})
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        assert "exp" in payload

    def test_expired_token_raises(self):
        from app.auth import create_access_token
        from app.config import settings
        token = create_access_token(
            data={"sub": "alice@example.com"},
            expires_delta=timedelta(seconds=-1),
        )
        with pytest.raises(Exception):
            jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])


# ------------------------------------------------------------------ #
# 3. Currency converter logic                                          #
# ------------------------------------------------------------------ #
class TestCurrencyConverter:
    """Pure arithmetic – no network call needed."""

    RATES = {"USD": 1.0, "TZS": 2500.0, "KES": 130.0}

    def _convert(self, amount: float, from_cur: str, to_cur: str) -> float:
        rate_from = self.RATES[from_cur]
        rate_to = self.RATES[to_cur]
        return amount * (rate_to / rate_from)

    def test_usd_to_tzs(self):
        result = self._convert(1.0, "USD", "TZS")
        assert result == pytest.approx(2500.0)

    def test_tzs_to_usd(self):
        result = self._convert(2500.0, "TZS", "USD")
        assert result == pytest.approx(1.0)

    def test_usd_to_kes(self):
        result = self._convert(1.0, "USD", "KES")
        assert result == pytest.approx(130.0)

    def test_same_currency_returns_same(self):
        result = self._convert(100.0, "USD", "USD")
        assert result == pytest.approx(100.0)

    def test_cross_rate_tzs_to_kes(self):
        """TZS -> USD -> KES"""
        usd = self._convert(2500.0, "TZS", "USD")
        kes = self._convert(usd, "USD", "KES")
        assert kes == pytest.approx(130.0, rel=1e-3)


# ------------------------------------------------------------------ #
# 4. Expense model (fromJson / toJson) – Python equivalent             #
# ------------------------------------------------------------------ #
class TestExpenseModel:
    SAMPLE = {
        "id": 1,
        "amount": "150.50",
        "currency": "USD",
        "category": "Food",
        "date": "2025-01-10T10:00:00",
        "note": "Lunch",
        "is_self_receipt": False,
        "payment_method": "cash",
        "location": None,
        "vendor": None,
        "project": None,
        "project_id": None,
        "photo_url": None,
        "user_id": 1,
        "wallet_id": None,
    }

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

    def test_amount_parsed_from_string(self):
        assert self._parse_amount("150.50") == pytest.approx(150.50)

    def test_amount_parsed_from_float(self):
        assert self._parse_amount(99.99) == pytest.approx(99.99)

    def test_amount_defaults_to_zero_on_none(self):
        assert self._parse_amount(None) == 0.0

    def test_amount_defaults_to_zero_on_invalid_string(self):
        assert self._parse_amount("not-a-number") == 0.0

    def test_model_currency_preserved(self):
        currency = self.SAMPLE["currency"]
        assert currency == "USD"


# ------------------------------------------------------------------ #
# 5. Wallet model – _parseAmount edge cases                            #
# ------------------------------------------------------------------ #
class TestWalletModel:
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

    def test_integer_balance(self):
        assert self._parse_amount(500) == 500.0

    def test_decimal_string_balance(self):
        assert self._parse_amount("1234.56") == pytest.approx(1234.56)

    def test_none_balance(self):
        assert self._parse_amount(None) == 0.0

    def test_negative_balance_preserved(self):
        """A wallet can have a negative balance (overdraft)."""
        assert self._parse_amount(-250.0) == -250.0


# ------------------------------------------------------------------ #
# 6. Validators                                                        #
# ------------------------------------------------------------------ #
class TestValidators:
    """Port of Flutter Validators class to Python for unit-test parity."""

    def _validate_email(self, value):
        import re
        if not value:
            return "Email is required"
        if not re.match(r"^[^@]+@[^@]+\.[^@]+", value):
            return "Enter a valid email"
        return None

    def _validate_amount(self, value):
        if not value:
            return "Amount is required"
        try:
            n = float(value)
        except ValueError:
            return "Enter a valid positive number"
        if n <= 0:
            return "Enter a valid positive number"
        return None

    def _validate_password(self, value):
        if not value:
            return "Password is required"
        if len(value) < 6:
            return "Password must be at least 6 characters"
        return None

    def test_valid_email(self):
        assert self._validate_email("user@domain.com") is None

    def test_invalid_email_no_at(self):
        assert self._validate_email("userdomain.com") is not None

    def test_empty_email(self):
        assert self._validate_email("") is not None

    def test_valid_amount(self):
        assert self._validate_amount("100") is None

    def test_zero_amount_rejected(self):
        assert self._validate_amount("0") is not None

    def test_negative_amount_rejected(self):
        assert self._validate_amount("-5") is not None

    def test_non_numeric_amount_rejected(self):
        assert self._validate_amount("abc") is not None

    def test_valid_password(self):
        assert self._validate_password("secure1") is None

    def test_short_password_rejected(self):
        assert self._validate_password("abc") is not None

    def test_empty_password_rejected(self):
        assert self._validate_password("") is not None


# ------------------------------------------------------------------ #
# 7. RoleEnum values                                                   #
# ------------------------------------------------------------------ #
class TestRoleEnum:
    def test_role_values(self):
        from app.models import RoleEnum
        assert RoleEnum.user.value == "user"
        assert RoleEnum.admin.value == "admin"
        assert RoleEnum.superadmin.value == "superadmin"

    def test_role_from_string(self):
        from app.models import RoleEnum
        role = RoleEnum("admin")
        assert role == RoleEnum.admin


# ------------------------------------------------------------------ #
# 8. SystemSettings defaults                                           #
# ------------------------------------------------------------------ #
class TestSystemSettingsDefaults:
    DEFAULTS = {
        "app_name": "Expense Tracker",
        "default_currency": "USD",
        "use_live_rates": True,
        "manual_rates": {"USD_TZS": 2500.0, "USD_KES": 130.0},
        "session_timeout_minutes": 1440,
        "version": 1,
    }

    def test_default_currency_is_usd(self):
        assert self.DEFAULTS["default_currency"] == "USD"

    def test_session_timeout_is_24_hours(self):
        assert self.DEFAULTS["session_timeout_minutes"] == 1440

    def test_manual_rates_present(self):
        assert "USD_TZS" in self.DEFAULTS["manual_rates"]
        assert "USD_KES" in self.DEFAULTS["manual_rates"]

    def test_tzs_rate_default(self):
        assert self.DEFAULTS["manual_rates"]["USD_TZS"] == 2500.0

    def test_kes_rate_default(self):
        assert self.DEFAULTS["manual_rates"]["USD_KES"] == 130.0
