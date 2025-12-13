#!/usr/bin/env python3
"""
Quick migration runner with hardcoded DATABASE_URL
"""

import os
import asyncio

# Set the public Railway database URL
os.environ['DATABASE_URL'] = 'postgresql://postgres:EKnvPEjgBLKVliLVvZsrgxfpNTZwfDkx@shuttle.proxy.rlwy.net:20901/railway'

from migrate_tables import migrate_database

if __name__ == "__main__":
    print("🔧 Running database migration...")
    asyncio.run(migrate_database())
