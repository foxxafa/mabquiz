from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from ..models.user import UserCreate, UserLogin, UserResponse, UserDB, GoogleAuthData
from ..auth.jwt_handler import create_access_token, verify_token
from ..auth.password_utils import hash_password, verify_password
from ..db import get_session
import uuid
import os
from datetime import datetime

# Google auth imports - lazy load to avoid import errors
try:
    from google.oauth2 import id_token
    from google.auth.transport import requests as google_requests
    GOOGLE_AUTH_AVAILABLE = True
    print("✅ Google auth libraries loaded successfully")
except ImportError as e:
    GOOGLE_AUTH_AVAILABLE = False
    print(f"⚠️ Google auth libraries not available: {e}")

router = APIRouter(prefix="/auth", tags=["authentication"])
security = HTTPBearer()

@router.post("/register", response_model=UserResponse)
async def register(user_data: UserCreate, db: AsyncSession = Depends(get_session)):
    """Register new user"""
    
    # Check if email already exists
    from sqlalchemy import select, or_
    result = await db.execute(
        select(UserDB).filter(
            or_(UserDB.email == user_data.email, UserDB.username == user_data.username)
        )
    )
    existing_user = result.scalar_one_or_none()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email or username already registered"
        )
    
    # Create new user (no password validation)
    hashed_password = hash_password(user_data.password)
    user_uid = str(uuid.uuid4())
    
    db_user = UserDB(
        uid=user_uid,
        email=user_data.email,
        username=user_data.username,
        password_hash=hashed_password,
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        display_name=f"{user_data.first_name} {user_data.last_name}",
        department=user_data.department,
        email_verified=False
    )
    
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    
    return UserResponse(
        uid=db_user.uid,
        email=db_user.email,
        display_name=db_user.display_name,
        email_verified=db_user.email_verified
    )

@router.post("/login")
async def login(login_data: UserLogin, db: AsyncSession = Depends(get_session)):
    """Login user and return JWT token"""
    
    # Find user by username
    from sqlalchemy import select
    result = await db.execute(select(UserDB).filter(UserDB.username == login_data.username))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials"
        )
    
    # Verify password
    if not verify_password(login_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials"
        )
    
    # Create access token
    token_data = {
        "uid": user.uid,
        "email": user.email,
        "display_name": user.display_name
    }
    access_token = create_access_token(token_data)
    
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": UserResponse(
            uid=user.uid,
            email=user.email,
            display_name=user.display_name,
            email_verified=user.email_verified
        )
    }

@router.post("/google")
async def google_auth(auth_data: GoogleAuthData, db: AsyncSession = Depends(get_session)):
    """Authenticate with Google OAuth"""

    if not GOOGLE_AUTH_AVAILABLE:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Google authentication is not available"
        )

    try:
        # Verify Google ID token
        idinfo = id_token.verify_oauth2_token(
            auth_data.id_token,
            google_requests.Request(),
            os.getenv("GOOGLE_CLIENT_ID")
        )
        
        email = idinfo['email']
        google_id = idinfo['sub']
        name = idinfo.get('name', '')
        
        # Check if user exists
        from sqlalchemy import select
        result = await db.execute(select(UserDB).filter(UserDB.email == email))
        user = result.scalar_one_or_none()
        
        if not user:
            # Create new user
            user_uid = str(uuid.uuid4())
            user = UserDB(
                uid=user_uid,
                email=email,
                display_name=name,
                google_id=google_id,
                email_verified=True
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)
        
        # Create access token
        token_data = {
            "uid": user.uid,
            "email": user.email,
            "display_name": user.display_name
        }
        access_token = create_access_token(token_data)
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user": UserResponse(
                uid=user.uid,
                email=user.email,
                display_name=user.display_name,
                email_verified=user.email_verified
            )
        }
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Google token"
        )

@router.get("/me", response_model=UserResponse)
async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_session)
):
    """Get current user info"""
    
    # Verify token
    payload = verify_token(credentials.credentials)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    
    # Get user from database
    from sqlalchemy import select
    result = await db.execute(select(UserDB).filter(UserDB.uid == payload.get("uid")))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return UserResponse(
        uid=user.uid,
        email=user.email,
        display_name=user.display_name,
        email_verified=user.email_verified
    )

@router.post("/logout")
async def logout(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    """Logout user"""
    
    # Since we're using stateless JWT tokens, logout is handled client-side
    # The token will expire based on its expiration time
    
    return {"message": "Logged out successfully"}