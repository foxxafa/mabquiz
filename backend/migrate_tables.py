#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Comprehensive database migration script for MAB Quiz System
This script safely migrates existing tables and creates new ones
"""

import asyncio
import os
import sys
import io

# Fix Windows console encoding
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import text, inspect
from app.models import Base
from app.models.user import UserDB
from app.models.question import Question
from app.models.question_metrics import QuestionMetrics, StudentResponse
from app.models.quiz_session import UserQuizSession
from app.models.mab_state import UserMABQuestionArm, UserMABTopicArm


async def check_table_exists(conn, table_name: str) -> bool:
    """Check if a table exists in the database"""
    result = await conn.execute(text(f"""
        SELECT EXISTS (
            SELECT FROM information_schema.tables
            WHERE table_name = '{table_name}'
        );
    """))
    return result.scalar()


async def backup_existing_data(conn, table_name: str):
    """Backup existing table data before migration"""
    exists = await check_table_exists(conn, table_name)
    if not exists:
        print(f"  ⏭️  Table '{table_name}' doesn't exist, skipping backup")
        return None

    # Create backup table
    backup_table = f"{table_name}_backup_{int(asyncio.get_event_loop().time())}"
    await conn.execute(text(f"CREATE TABLE {backup_table} AS SELECT * FROM {table_name}"))
    print(f"  ✅ Backed up '{table_name}' to '{backup_table}'")
    return backup_table


async def migrate_questions_table(conn):
    """Migrate questions table with new columns"""
    print("\n📋 Migrating 'questions' table...")

    exists = await check_table_exists(conn, 'questions')
    if not exists:
        print("  ℹ️  Table doesn't exist, will be created from scratch")
        return

    # Check existing columns
    result = await conn.execute(text("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = 'questions'
    """))
    existing_columns = {row[0]: row[1] for row in result.fetchall()}
    print(f"  📊 Found {len(existing_columns)} existing columns")

    # Add new columns if they don't exist
    new_columns = {
        'course': "VARCHAR(64) NOT NULL DEFAULT 'general'",
        'topic': "VARCHAR(128) NOT NULL DEFAULT 'general'",
        'subtopic': "VARCHAR(128)",
        'knowledge_type': "VARCHAR(64) NOT NULL DEFAULT 'general'",
        'tags': "JSON",
        'correct_answer': "VARCHAR(255) NOT NULL DEFAULT ''",
        'explanation': "TEXT",
        'initial_confidence': "FLOAT DEFAULT 0.5",
        'points': "INTEGER DEFAULT 10",
        'created_at': "TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
        'updated_at': "TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
        'is_active': "BOOLEAN DEFAULT TRUE",
    }

    for col_name, col_def in new_columns.items():
        if col_name not in existing_columns:
            try:
                await conn.execute(text(f"ALTER TABLE questions ADD COLUMN {col_name} {col_def}"))
                print(f"  ✅ Added column '{col_name}'")
            except Exception as e:
                print(f"  ⚠️  Could not add '{col_name}': {e}")

    # Rename options_json to options if it exists
    if 'options_json' in existing_columns and 'options' not in existing_columns:
        try:
            await conn.execute(text("ALTER TABLE questions RENAME COLUMN options_json TO options"))
            await conn.execute(text("ALTER TABLE questions ALTER COLUMN options TYPE JSON USING options::json"))
            print(f"  ✅ Renamed 'options_json' to 'options' and converted to JSON type")
        except Exception as e:
            print(f"  ⚠️  Could not rename options_json: {e}")

    # Create indexes
    try:
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_questions_course ON questions(course)"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_questions_topic ON questions(topic)"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_questions_knowledge_type ON questions(knowledge_type)"))
        print("  ✅ Created indexes")
    except Exception as e:
        print(f"  ⚠️  Index creation warning: {e}")


async def migrate_database():
    """Run comprehensive database migration"""

    # Get database URL from environment
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        print("❌ ERROR: DATABASE_URL environment variable not set")
        sys.exit(1)

    # Fix Railway PostgreSQL URL if needed
    if database_url.startswith("postgres://"):
        database_url = database_url.replace("postgres://", "postgresql+asyncpg://", 1)
    elif not database_url.startswith("postgresql+asyncpg://"):
        database_url = database_url.replace("postgresql://", "postgresql+asyncpg://")

    print("=" * 60)
    print("🚀 MAB Quiz Database Migration")
    print("=" * 60)
    print(f"📍 Database: {database_url.split('@')[0]}@****")

    try:
        # Create async engine
        engine = create_async_engine(database_url, echo=False)

        async with engine.begin() as conn:
            # Step 1: Check existing tables
            print("\n📊 Checking existing tables...")
            result = await conn.execute(text("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
            """))
            existing_tables = [row[0] for row in result.fetchall()]
            print(f"  Found {len(existing_tables)} existing tables: {', '.join(existing_tables)}")

            # Step 2: Migrate existing tables
            if 'questions' in existing_tables:
                await migrate_questions_table(conn)

            # Step 3: Create new tables (this will skip existing ones)
            print("\n🏗️  Creating new tables...")
            await conn.run_sync(Base.metadata.create_all)
            print("  ✅ All tables created/verified")

            # Step 4: Verify all tables exist
            print("\n🔍 Verifying tables...")
            result = await conn.execute(text("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                ORDER BY table_name
            """))
            final_tables = [row[0] for row in result.fetchall()]

            print(f"\n✅ Database migration completed successfully!")
            print(f"\n📋 Final table list ({len(final_tables)} tables):")
            for table in final_tables:
                print(f"  • {table}")

        # Close engine
        await engine.dispose()

    except Exception as e:
        print(f"\n❌ Migration failed: {str(e)}")
        import traceback
        print(traceback.format_exc())
        sys.exit(1)


async def verify_schema():
    """Verify that all required tables and columns exist"""
    database_url = os.getenv("DATABASE_URL")
    if database_url.startswith("postgres://"):
        database_url = database_url.replace("postgres://", "postgresql+asyncpg://", 1)

    engine = create_async_engine(database_url, echo=False)

    print("\n" + "=" * 60)
    print("🔍 Schema Verification")
    print("=" * 60)

    async with engine.begin() as conn:
        # Check each table
        required_tables = [
            'users',
            'questions',
            'question_metrics',
            'student_responses',
            'user_quiz_sessions',
            'user_mab_question_arms',
            'user_mab_topic_arms',
        ]

        for table in required_tables:
            exists = await check_table_exists(conn, table)
            if exists:
                # Count rows
                result = await conn.execute(text(f"SELECT COUNT(*) FROM {table}"))
                count = result.scalar()
                print(f"  ✅ {table:<30} ({count} rows)")
            else:
                print(f"  ❌ {table:<30} MISSING!")

    await engine.dispose()


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='MAB Quiz Database Migration')
    parser.add_argument('--verify-only', action='store_true', help='Only verify schema without migration')
    args = parser.parse_args()

    if args.verify_only:
        asyncio.run(verify_schema())
    else:
        asyncio.run(migrate_database())
        asyncio.run(verify_schema())