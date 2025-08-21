import os
from typing import AsyncGenerator
from sqlalchemy import create_engine
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import sessionmaker, Session

# Railway PostgreSQL database URL
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    # Development fallback
    DATABASE_URL = "mysql+aiomysql://root:password@localhost:3306/mabquiz"
elif DATABASE_URL.startswith("postgres://"):
    # Railway PostgreSQL URL fix
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# Async engine for FastAPI
async_engine = create_async_engine(DATABASE_URL, echo=False, pool_pre_ping=True)
AsyncSessionLocal = async_sessionmaker(async_engine, expire_on_commit=False, class_=AsyncSession)

# Sync engine for Celery and batch jobs
sync_database_url = DATABASE_URL.replace("+asyncpg", "").replace("+aiomysql", "")
if "postgresql://" in sync_database_url:
    sync_database_url = sync_database_url.replace("postgresql://", "postgresql+psycopg2://")
elif "mysql://" in sync_database_url:
    sync_database_url = sync_database_url.replace("mysql://", "mysql+pymysql://")

sync_engine = create_engine(sync_database_url, echo=False, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=sync_engine)

# Async session generator for FastAPI
async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session

# Sync session generator for Celery
def get_db() -> AsyncGenerator[Session, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# For backward compatibility
get_db = get_session
