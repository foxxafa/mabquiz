from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncEngine
from sqlalchemy.ext.asyncio import create_async_engine
from contextlib import asynccontextmanager

from .routers import router
from .models import Base
from .db import DATABASE_URL

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    try:
        from sqlalchemy import text
        engine: AsyncEngine = create_async_engine(DATABASE_URL, echo=False)
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
            # Test connection
            await conn.execute(text("SELECT 1"))
        print("✅ Database tables created successfully")
    except Exception as e:
        print(f"❌ Database connection error: {e}")
    
    yield
    
    # Shutdown (cleanup if needed)
    pass

app = FastAPI(title="MAB Quiz API", version="0.1.0", lifespan=lifespan)

# CORS (Flutter için localhost ve mobil emülatör adresleri)
origins = [
    "http://localhost",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://10.0.2.2:8080",  # Android emulator
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routes
app.include_router(router)

@app.get("/health")
async def health():
    try:
        # Simple database connection test
        from .db import SessionLocal
        async with SessionLocal() as session:
            from sqlalchemy import text
            result = await session.execute(text("SELECT 1 as test"))
            test_result = result.scalar()
        return {"status": "ok", "database": "connected", "test_query": test_result}
    except Exception as e:
        return {"status": "error", "database": "disconnected", "error": str(e)}
