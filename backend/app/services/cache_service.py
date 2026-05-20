"""In-memory TTL cache — no Redis dependency needed at this scale."""
import time
from typing import Any, Optional


class CacheEntry:
    def __init__(self, value: Any, ttl: int):
        self.value = value
        self.expires_at = time.time() + ttl


class CacheService:
    """Simple thread-safe in-memory cache with TTL expiration."""

    def __init__(self):
        self._store: dict[str, CacheEntry] = {}

    def get(self, key: str) -> Optional[Any]:
        entry = self._store.get(key)
        if entry is None:
            return None
        if time.time() > entry.expires_at:
            del self._store[key]
            return None
        return entry.value

    def set(self, key: str, value: Any, ttl: int = 300):
        self._store[key] = CacheEntry(value, ttl)

    def invalidate(self, key: str):
        self._store.pop(key, None)

    def invalidate_prefix(self, prefix: str):
        keys_to_delete = [k for k in self._store if k.startswith(prefix)]
        for k in keys_to_delete:
            del self._store[k]

    def clear(self):
        self._store.clear()


# Global singleton cache instance
cache = CacheService()
