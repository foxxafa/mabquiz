import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncEngine
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

# Import directly from routers/main.py
print("🔧 Attempting to import main router...")
try:
    from .routers.main import router
    print("✅ Main router imported successfully")
    print(f"🔍 Main router routes: {[route.path for route in router.routes]}")
except Exception as e:
    print(f"❌ Main router import failed: {e}")
    import traceback
    print(f"❌ Full traceback: {traceback.format_exc()}")
    raise
from .models import Base
from .models.user import UserDB
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

# Manual auth endpoints as fallback
from fastapi import HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from .db import get_session
import uuid
import json

@app.post("/api/v1/auth/register")
async def manual_register(request: dict, db: AsyncSession = Depends(get_session)):
    """Manual register endpoint"""
    try:
        from .models.user import UserDB
        from .auth.password_utils import hash_password
        from sqlalchemy import select
        
        # Extract data
        email = request.get("email")
        password = request.get("password")
        first_name = request.get("first_name")
        last_name = request.get("last_name")
        department = request.get("department", "general")
        
        # Check if user exists
        result = await db.execute(select(UserDB).filter(UserDB.email == email))
        if result.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Email already registered")
        
        # Create user
        hashed_password = hash_password(password)
        user_uid = str(uuid.uuid4())
        
        db_user = UserDB(
            uid=user_uid,
            email=email,
            password_hash=hashed_password,
            first_name=first_name,
            last_name=last_name,
            display_name=f"{first_name} {last_name}",
            department=department,
            email_verified=False
        )
        
        db.add(db_user)
        await db.commit()
        await db.refresh(db_user)
        
        return {
            "uid": db_user.uid,
            "email": db_user.email,
            "display_name": db_user.display_name,
            "email_verified": db_user.email_verified
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.on_event("startup")
async def on_startup():
    """Application startup tasks"""
    environment = os.getenv("RAILWAY_ENVIRONMENT_NAME", "development")
    
    if environment == "development":
        # Auto-create tables in development
        print("🔧 Development mode: Auto-creating tables...")
        async with async_engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        print("✅ Tables created/verified")
    else:
        # In production, just verify connection
        print("🚀 Production mode: Verifying database connection...")
        try:
            async with async_engine.begin() as conn:
                await conn.execute(text("SELECT 1"))
            print("✅ Database connection verified")
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            raise

@app.get("/health")
async def health():
    # Check database connection
    db_status = "unknown"
    try:
        async with async_engine.begin() as conn:
            await conn.execute(text("SELECT 1"))
        db_status = "connected"
    except Exception:
        db_status = "disconnected"
    
    return {
        "status": "ok",
        "version": "1.0.0",
        "environment": os.getenv("RAILWAY_ENVIRONMENT_NAME", "development"),
        "service": os.getenv("RAILWAY_SERVICE_NAME", "mabquiz-backend"),
        "database": db_status,
        "timestamp": os.popen("date").read().strip()
    }
