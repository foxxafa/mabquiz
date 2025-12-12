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
    "https://attractive-quietude-production-25a0.up.railway.app",  # Web admin
    "https://mabquiz-production.up.railway.app",  # Backend
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

# Manual auth endpoints as fallback
from fastapi import HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from .db import get_session
import uuid
import json

# Simple manual endpoint without complex types
import json as json_lib

from fastapi import Request

@app.post("/api/v1/auth/register")
async def manual_register(request: Request, db: AsyncSession = Depends(get_session)):
    """Manual register endpoint"""
    try:
        from .models.user import UserDB
        from .auth.password_utils import hash_password
        from sqlalchemy import select
        
        # Parse JSON from request
        body = await request.json()
        email = body.get("email")
        username = body.get("username")
        password = body.get("password") 
        first_name = body.get("first_name")
        last_name = body.get("last_name")
        department = body.get("department", "general")
        
        # Check if user exists (email or username)
        email_check = await db.execute(select(UserDB).filter(UserDB.email == email))
        username_check = await db.execute(select(UserDB).filter(UserDB.username == username))
        if email_check.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Email already registered")
        if username_check.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Username already taken")
        
        # Create user
        hashed_password = hash_password(password)
        user_uid = str(uuid.uuid4())
        
        db_user = UserDB(
            uid=user_uid,
            email=email,
            username=username,
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

@app.post("/api/v1/auth/login")
async def manual_login(request: Request, db: AsyncSession = Depends(get_session)):
    """Manual login endpoint"""
    try:
        from .models.user import UserDB
        from .auth.password_utils import verify_password
        from .auth.jwt_handler import create_access_token
        from sqlalchemy import select
        
        # Parse JSON from request
        body = await request.json()
        username = body.get("username")
        password = body.get("password")
        
        # Find user by username
        result = await db.execute(select(UserDB).filter(UserDB.username == username))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        # Verify password
        if not verify_password(password, user.password_hash):
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        # Create token
        token_data = {
            "uid": user.uid,
            "email": user.email,
            "display_name": user.display_name
        }
        access_token = create_access_token(token_data)
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user": {
                "uid": user.uid,
                "email": user.email,
                "display_name": user.display_name,
                "email_verified": user.email_verified
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/auth/me")
async def get_current_user(request: Request, db: AsyncSession = Depends(get_session)):
    """Get current user info"""
    try:
        from .models.user import UserDB
        from .auth.jwt_handler import verify_token
        from sqlalchemy import select
        
        # Get token from header
        auth_header = request.headers.get("authorization")
        if not auth_header or not auth_header.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Missing or invalid token")
        
        token = auth_header.split(" ")[1]
        payload = verify_token(token)
        if not payload:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        # Get user from database
        result = await db.execute(select(UserDB).filter(UserDB.uid == payload.get("uid")))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        return {
            "uid": user.uid,
            "email": user.email,
            "display_name": user.display_name,
            "email_verified": user.email_verified
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

async def run_migrations(conn):
    """Run database migrations"""
    print("🔄 Running database migrations...")

    # Check if user_mab_question_arms has 'difficulty' column (should be removed)
    result = await conn.execute(text("""
        SELECT column_name FROM information_schema.columns
        WHERE table_name = 'user_mab_question_arms' AND column_name = 'difficulty'
    """))
    if result.fetchone():
        print("  📋 Removing 'difficulty' column from user_mab_question_arms...")
        await conn.execute(text("ALTER TABLE user_mab_question_arms DROP COLUMN difficulty"))
        print("  ✅ Dropped 'difficulty' column")

    # Check if user_mab_topic_arms has 'last_updated' column (should be renamed to 'updated_at')
    result = await conn.execute(text("""
        SELECT column_name FROM information_schema.columns
        WHERE table_name = 'user_mab_topic_arms' AND column_name = 'last_updated'
    """))
    if result.fetchone():
        print("  📋 Renaming 'last_updated' to 'updated_at' in user_mab_topic_arms...")
        await conn.execute(text("ALTER TABLE user_mab_topic_arms RENAME COLUMN last_updated TO updated_at"))
        print("  ✅ Renamed column")

    print("✅ Migrations completed")


@app.on_event("startup")
async def on_startup():
    """Application startup tasks"""
    environment = os.getenv("RAILWAY_ENVIRONMENT_NAME", "development")

    print("🚀 Starting application...")
    try:
        async with async_engine.begin() as conn:
            # Verify connection
            await conn.execute(text("SELECT 1"))
            print("✅ Database connection verified")

            # Run migrations
            await run_migrations(conn)

            # Create tables if they don't exist
            await conn.run_sync(Base.metadata.create_all)
            print("✅ Tables created/verified")
    except Exception as e:
        print(f"❌ Startup failed: {e}")
        import traceback
        print(traceback.format_exc())
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
