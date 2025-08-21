from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from ..models.user import UserCreate, UserLogin, UserResponse, UserDB, GoogleAuthData
from ..auth.jwt_handler import create_access_token, verify_token
from ..auth.password_utils import hash_password, verify_password
import uuid
import os
from datetime import datetime
from google.oauth2 import id_token
from google.auth.transport import requests
from ..cache.redis_manager import redis_manager

router = APIRouter(prefix="/auth", tags=["authentication"])
security = HTTPBearer()

# Database setup (will be moved to proper config later)
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./auth.db")
engine = create_engine(DATABASE_URL)

def get_db():
    from sqlalchemy.orm import sessionmaker
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/register", response_model=UserResponse)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """Register new user"""
    
    # Check if user already exists
    existing_user = db.query(UserDB).filter(UserDB.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    hashed_password = hash_password(user_data.password)
    user_uid = str(uuid.uuid4())
    
    db_user = UserDB(
        uid=user_uid,
        email=user_data.email,
        password_hash=hashed_password,
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        display_name=f"{user_data.first_name} {user_data.last_name}",
        department=user_data.department,
        email_verified=False
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return UserResponse(
        uid=db_user.uid,
        email=db_user.email,
        display_name=db_user.display_name,
        email_verified=db_user.email_verified
    )

@router.post("/login")
async def login(login_data: UserLogin, db: Session = Depends(get_db)):
    """Login user and return JWT token"""
    
    # Find user by email
    user = db.query(UserDB).filter(UserDB.email == login_data.email).first()
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
    
    # Store session in Redis
    session_data = {
        "uid": user.uid,
        "email": user.email,
        "display_name": user.display_name,
        "login_time": datetime.utcnow().isoformat()
    }
    await redis_manager.set_session(user.uid, session_data)
    
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
async def google_auth(auth_data: GoogleAuthData, db: Session = Depends(get_db)):
    """Authenticate with Google OAuth"""
    
    try:
        # Verify Google ID token
        idinfo = id_token.verify_oauth2_token(
            auth_data.id_token, 
            requests.Request(), 
            os.getenv("GOOGLE_CLIENT_ID")
        )
        
        email = idinfo['email']
        google_id = idinfo['sub']
        name = idinfo.get('name', '')
        
        # Check if user exists
        user = db.query(UserDB).filter(UserDB.email == email).first()
        
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
            db.commit()
            db.refresh(user)
        
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
    db: Session = Depends(get_db)
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
    user = db.query(UserDB).filter(UserDB.uid == payload.get("uid")).first()
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
    """Logout user and clear Redis session"""
    
    # Get user from token
    payload = verify_token(credentials.credentials)
    if payload:
        user_uid = payload.get("uid")
        if user_uid:
            # Clear Redis session
            await redis_manager.delete_session(user_uid)
    
    return {"message": "Logged out successfully"}