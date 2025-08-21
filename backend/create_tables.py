#!/usr/bin/env python3
"""
Database table creation script for MAB Quiz System
Run this script to create all necessary tables in PostgreSQL
"""

import asyncio
import os
import sys
from sqlalchemy.ext.asyncio import create_async_engine
from app.models import Base
from app.models.user import UserDB
from app.models.question_metrics import QuestionMetrics, StudentResponse

async def create_tables():
    """Create all database tables"""
    
    # Get database URL from environment
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        print("ERROR: DATABASE_URL environment variable not set")
        sys.exit(1)
    
    # Fix Railway PostgreSQL URL if needed
    if database_url.startswith("postgres://"):
        database_url = database_url.replace("postgres://", "postgresql+asyncpg://", 1)
    elif not database_url.startswith("postgresql+asyncpg://"):
        database_url = database_url.replace("postgresql://", "postgresql+asyncpg://")
    
    print(f"Connecting to database...")
    print(f"Database URL: {database_url.split('@')[0]}@****")
    
    try:
        # Create async engine
        engine = create_async_engine(database_url, echo=True)
        
        # Create all tables
        async with engine.begin() as conn:
            print("Creating all tables...")
            await conn.run_sync(Base.metadata.create_all)
            print("✅ All tables created successfully!")
        
        # Close engine
        await engine.dispose()
        
    except Exception as e:
        print(f"❌ Error creating tables: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(create_tables())