#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Database migration script for MAB Quiz System
"""

import asyncio
import os
import sys
import io

# Fix Windows console encoding
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.models import Base
from app.models.knowledge_type import DEFAULT_KNOWLEDGE_TYPES


async def check_table_exists(conn, table_name: str) -> bool:
    """Check if a table exists in the database"""
    result = await conn.execute(text(f"""
        SELECT EXISTS (
            SELECT FROM information_schema.tables
            WHERE table_name = '{table_name}'
        );
    """))
    return result.scalar()


async def migrate_knowledge_types_table(conn):
    """Drop and recreate knowledge_types table with Bloom taxonomy types"""
    print("\n📋 Migrating 'knowledge_types' table...")

    exists = await check_table_exists(conn, 'knowledge_types')

    if exists:
        # Check if any questions reference knowledge_types
        try:
            result = await conn.execute(text("""
                SELECT COUNT(*) FROM questions WHERE knowledge_type_id IS NOT NULL
            """))
            question_count = result.scalar() or 0

            if question_count > 0:
                print(f"  ⚠️  {question_count} questions reference knowledge_types")
                await conn.execute(text("UPDATE questions SET knowledge_type_id = NULL"))
                print("  ✅ Set all question knowledge_type_id to NULL")
        except Exception as e:
            print(f"  ⚠️  Could not check questions: {e}")

        # Drop the table
        await conn.execute(text("DROP TABLE IF EXISTS knowledge_types CASCADE"))
        print("  ✅ Dropped old knowledge_types table")

    # Create new table
    await conn.execute(text("""
        CREATE TABLE knowledge_types (
            id SERIAL PRIMARY KEY,
            name VARCHAR(50) UNIQUE NOT NULL,
            display_name VARCHAR(100) NOT NULL,
            description TEXT,
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        )
    """))
    print("  ✅ Created new knowledge_types table")

    # Insert default Bloom taxonomy types
    for kt in DEFAULT_KNOWLEDGE_TYPES:
        await conn.execute(text("""
            INSERT INTO knowledge_types (name, display_name, description)
            VALUES (:name, :display_name, :description)
        """), kt)

    print(f"  ✅ Inserted {len(DEFAULT_KNOWLEDGE_TYPES)} Bloom taxonomy knowledge types")

    # Create index
    await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_knowledge_types_name ON knowledge_types(name)"))
    print("  ✅ Created index on knowledge_types")


async def migrate_database():
    """Run database migration"""

    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        print("❌ ERROR: DATABASE_URL environment variable not set")
        sys.exit(1)

    # Fix Railway PostgreSQL URL
    if database_url.startswith("postgres://"):
        database_url = database_url.replace("postgres://", "postgresql+asyncpg://", 1)
    elif not database_url.startswith("postgresql+asyncpg://"):
        database_url = database_url.replace("postgresql://", "postgresql+asyncpg://")

    print("=" * 60)
    print("🚀 MAB Quiz Database Migration")
    print("=" * 60)

    try:
        engine = create_async_engine(database_url, echo=False)

        async with engine.begin() as conn:
            # Migrate knowledge_types table
            await migrate_knowledge_types_table(conn)

            # Create any missing tables
            print("\n🏗️  Creating/verifying tables...")
            await conn.run_sync(Base.metadata.create_all)
            print("  ✅ All tables verified")

            # Show final table list
            result = await conn.execute(text("""
                SELECT table_name FROM information_schema.tables
                WHERE table_schema = 'public' ORDER BY table_name
            """))
            tables = [row[0] for row in result.fetchall()]
            print(f"\n✅ Migration completed! ({len(tables)} tables)")

        await engine.dispose()

    except Exception as e:
        print(f"\n❌ Migration failed: {str(e)}")
        import traceback
        print(traceback.format_exc())
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(migrate_database())