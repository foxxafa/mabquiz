# Railway optimized Dockerfile for MAB Quiz Backend
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY backend/requirements.txt .

# Install Python dependencies (force fresh install with timestamp to break cache)
# Cache bust: 2025-12-12-v2
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir --force-reinstall google-auth==2.27.0 && \
    echo "=== Installed Google packages ===" && \
    pip list | grep -i google && \
    python -c "from google.oauth2 import id_token; from google.auth.transport import requests; print('✅ Google auth imports work!')"

# Copy application code
COPY backend/ .

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Command to run the application
# Use $PORT environment variable provided by Railway
CMD gunicorn app.main:app --bind 0.0.0.0:$PORT --workers 2 --worker-class uvicorn.workers.UvicornWorker