import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncEngine
from sqlalchemy.ext.asyncio import create_async_engine

from .routers import router
from .routers.difficulty import router as difficulty_router
from .routers.auth import router as auth_router
from .models import Base
from .db import async_engine

app = FastAPI(
    title="MAB Quiz API", 
    version="1.0.0",
    description="Multi-Armed Bandit Quiz System with Dynamic Difficulty"
)

# CORS - Production ve development ortamları için
origins = [
    "http://localhost",
    "http://localhost:8080", 
    "http://127.0.0.1:8080",
    "http://10.0.2.2:8080",  # Android emulator
    "https://*.up.railway.app",  # Railway domain
    "https://*.railway.app",     # Railway domain
]

# Railway production domain ekle
if os.getenv("RAILWAY_ENVIRONMENT_NAME"):
    railway_domain = f"https://{os.getenv('RAILWAY_SERVICE_NAME')}-production.up.railway.app"
    origins.append(railway_domain)

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routes
app.include_router(router)
app.include_router(difficulty_router)
app.include_router(auth_router)

@app.on_event("startup")
async def on_startup():
    # Auto-create tables if not exist (development convenience)
    async with async_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

@app.get("/health")
async def health():
    return {
        "status": "ok",
        "version": "1.0.0",
        "environment": os.getenv("RAILWAY_ENVIRONMENT_NAME", "development"),
        "service": os.getenv("RAILWAY_SERVICE_NAME", "mabquiz-backend")
    }
