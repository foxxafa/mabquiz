from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncEngine
from sqlalchemy.ext.asyncio import create_async_engine

from .routers import router
from .models import Base
from .db import DATABASE_URL

app = FastAPI(title="MAB Quiz API", version="0.1.0")

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

@app.on_event("startup")
async def on_startup():
    # Auto-create tables if not exist (development convenience)
    engine: AsyncEngine = create_async_engine(DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

@app.get("/health")
async def health():
    return {"status": "ok"}
