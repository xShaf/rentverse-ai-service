# Use Python 3.12 slim image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies
# Added 'curl' because your HEALTHCHECK command uses it!
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry

# Copy dependency files
COPY pyproject.toml poetry.lock ./

# Configure poetry and install dependencies
RUN poetry config virtualenvs.create false \
    && poetry install --without dev --no-interaction --no-ansi --no-root

# Copy application code
COPY . .

# --- FIX START ---
# Create non-root user WITH a home directory (-m)
RUN groupadd -r appuser && useradd -r -g appuser -m -d /home/appuser appuser

# Set permissions
RUN chown -R appuser:appuser /app

# Switch to the non-root user
USER appuser

# Explicitly set HOME variable so Python knows where to write cache
ENV HOME=/home/appuser
# --- FIX END ---

# Expose port
EXPOSE 8000

# Health check (Ensure 'curl' is installed in the apt-get step above)
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/v1/health || exit 1

# Run the application
# Use Shell form (no brackets) and use the PORT variable provided by Railway
CMD uvicorn rentverse.main:app --host 0.0.0.0 --port ${PORT:-8000}