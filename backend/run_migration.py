#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Quick migration runner with hardcoded DATABASE_URL
"""

import os
import sys

# Set the public Railway database URL
os.environ['DATABASE_URL'] = 'postgresql://postgres:EKnvPEjgBLKVliLVvZsrgxfpNTZwfDkx@shuttle.proxy.rlwy.net:20901/railway'

# Now run the migration
import asyncio
from migrate_tables import migrate_database, verify_schema

if __name__ == "__main__":
    print("🔧 Setting DATABASE_URL and running migration...")
    asyncio.run(migrate_database())
    asyncio.run(verify_schema())
