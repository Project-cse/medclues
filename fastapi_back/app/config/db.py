import asyncio
import asyncpg
from typing import Optional
from .config import settings

class Database:
    def __init__(self):
        self.pool: Optional[asyncpg.Pool] = None
        self.read_pool: Optional[asyncpg.Pool] = None

    async def connect(self, retries: int = 3):
        if self.pool:
            await self._ensure_read_pool()
            return True

        last_error = None
        for attempt in range(1, retries + 1):
            try:
                db_url = settings.DATABASE_URL or ""
                is_neon = "neon.tech" in db_url or "neon.tech" in (settings.PG_HOST or "")
                pool_kwargs = {
                    "min_size": max(1, int(getattr(settings, "DB_POOL_MIN", 2) or 2)),
                    "max_size": max(2, int(getattr(settings, "DB_POOL_MAX", 20) or 20)),
                    "timeout": 15,
                    "command_timeout": 30,
                    # Neon/PgBouncer: prepared plans break after migrations (schema change).
                    "statement_cache_size": 0 if is_neon else 100,
                }
                if settings.DATABASE_URL:
                    self.pool = await asyncpg.create_pool(
                        settings.DATABASE_URL,
                        ssl="require" if "neon.tech" in settings.DATABASE_URL else (True if settings.PG_SSL else False),
                        **pool_kwargs,
                    )
                else:
                    self.pool = await asyncpg.create_pool(
                        user=settings.PG_USER,
                        password=settings.PG_PASSWORD,
                        database=settings.PG_DATABASE,
                        host=settings.PG_HOST,
                        port=settings.PG_PORT,
                        ssl=settings.PG_SSL,
                        **pool_kwargs,
                    )
                print("PostgreSQL connected successfully (Python)")
                await self._ensure_read_pool()
                return True
            except Exception as e:
                last_error = e
                self.pool = None
                print(f"PostgreSQL connection error (attempt {attempt}/{retries}): {e}")
                if attempt < retries:
                    await asyncio.sleep(2)

        print(f"PostgreSQL connection failed after {retries} attempts: {last_error}")
        return False

    async def _ensure_read_pool(self):
        """Optional read replica pool for search / heavy SELECTs."""
        if self.read_pool:
            return
        read_url = (getattr(settings, "DATABASE_READ_URL", None) or "").strip()
        if not read_url or read_url == (settings.DATABASE_URL or "").strip():
            return
        try:
            is_neon = "neon.tech" in read_url
            self.read_pool = await asyncpg.create_pool(
                read_url,
                ssl="require" if is_neon else (True if settings.PG_SSL else False),
                min_size=1,
                max_size=max(2, int(getattr(settings, "DB_POOL_MAX", 20) or 20) // 2),
                timeout=15,
                command_timeout=30,
                statement_cache_size=0 if is_neon else 100,
            )
            print("PostgreSQL read replica pool ready")
        except Exception as e:
            self.read_pool = None
            print(f"Read replica pool skipped: {e}")

    async def disconnect(self):
        if self.read_pool:
            await self.read_pool.close()
            self.read_pool = None
        if self.pool:
            await self.pool.close()
            print("PostgreSQL pool closed")

    async def query(self, sql, *args):
        if not self.pool:
            connected = await self.connect()
            if not connected or not self.pool:
                raise ConnectionError("PostgreSQL is unavailable")
        async with self.pool.acquire() as connection:
            return await connection.fetch(sql, *args)

    async def execute(self, sql, *args):
        if not self.pool:
            connected = await self.connect()
            if not connected or not self.pool:
                raise ConnectionError("PostgreSQL is unavailable")
        async with self.pool.acquire() as connection:
            return await connection.execute(sql, *args)

    async def fetch_row(self, sql, *args):
        if not self.pool:
            connected = await self.connect()
            if not connected or not self.pool:
                raise ConnectionError("PostgreSQL is unavailable")
        async with self.pool.acquire() as connection:
            return await connection.fetchrow(sql, *args)

    async def executemany(self, sql, args_list):
        if not self.pool:
            connected = await self.connect()
            if not connected or not self.pool:
                raise ConnectionError("PostgreSQL is unavailable")
        async with self.pool.acquire() as connection:
            return await connection.executemany(sql, args_list)

    # Aliases for compatibility
    async def fetch_all(self, sql, *args):
        return await self.query(sql, *args)

    async def fetch_one(self, sql, *args):
        return await self.fetch_row(sql, *args)

db = Database()
