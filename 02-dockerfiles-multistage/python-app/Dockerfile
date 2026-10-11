# Use a slim, secure base image
FROM python:3.12-slim

# Avoid writing .pyc files & buffer stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# 1. Layer cache: copy dependencies first
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2. Security: Create an unprivileged non-root user
RUN useradd -m -u 1001 appuser && \
    chown -R appuser:appuser /app

# 3. Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

EXPOSE 5000

# Exec form CMD passes SIGTERM directly to the Python process
CMD ["python", "app.py"]
