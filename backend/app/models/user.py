from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.sql import func
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from . import Base

class UserDB(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    uid = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    password_hash = Column(String)
    display_name = Column(String)
    first_name = Column(String)
    last_name = Column(String)
    department = Column(String)
    email_verified = Column(Boolean, default=False)
    google_id = Column(String, unique=True, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class UserCreate(BaseModel):
    email: str
    password: str
    first_name: str
    last_name: str
    department: str

class UserLogin(BaseModel):
    email: str
    password: str

class UserResponse(BaseModel):
    uid: str
    email: str
    display_name: Optional[str]
    email_verified: bool
    
    class Config:
        from_attributes = True

class GoogleAuthData(BaseModel):
    id_token: str