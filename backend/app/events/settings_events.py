"""Event hooks for settings changes — cache invalidation and refresh triggers."""
from app.services.cache_service import cache


def on_settings_changed():
    """Invalidate all settings-related caches."""
    cache.invalidate("system_settings")
    cache.invalidate("system_stats")


def on_categories_changed():
    """Invalidate all category caches."""
    cache.invalidate_prefix("categories_")
    cache.invalidate("system_stats")


def on_user_changed():
    """Invalidate stats cache when users are modified."""
    cache.invalidate("system_stats")


def on_full_refresh():
    """Nuclear option — clear all caches."""
    cache.clear()
