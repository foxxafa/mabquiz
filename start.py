#!/usr/bin/env python3
import os
import sys
import subprocess

# Railway deployment script
if __name__ == "__main__":
    # Change to backend directory
    backend_dir = os.path.join(os.path.dirname(__file__), 'backend')
    os.chdir(backend_dir)
    
    # Get port from environment
    port = os.environ.get("PORT", "8000")
    
    # Start uvicorn
    cmd = ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", str(port)]
    subprocess.run(cmd)