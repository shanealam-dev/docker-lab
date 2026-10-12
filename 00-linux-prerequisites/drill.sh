#!/usr/bin/env bash
set -e

export PATH="/usr/local/bin:/opt/homebrew/bin:$HOME/.docker/bin:$PATH"

echo "=========================================="
echo "🐧 LAB 00: LINUX PREREQUISITES INTERACTIVE DRILL"
echo "=========================================="

docker run --rm alpine sh -c "
  echo ''
  echo '[Step 1] Current User Identity:'
  whoami && id

  echo ''
  echo '[Step 2] Creating unprivileged user appuser (UID 1001)...'
  adduser -u 1001 -s /bin/sh -D appuser
  grep appuser /etc/passwd

  echo ''
  echo '[Step 3] Creating folder structure & files...'
  mkdir -p /app/config && echo 'APP_ENV=production' > /app/config/.env
  touch /app/config/flag.lock
  ls -la /app/config

  echo ''
  echo '[Step 4] Setting ownership & permissions...'
  chown -R appuser:appuser /app
  chmod 755 /app && chmod 600 /app/config/.env
  ls -ld /app && ls -l /app/config/.env

  echo ''
  echo '[Step 5] Testing non-root user execution via su...'
  su appuser -c 'whoami && cat /app/config/.env'

  echo ''
  echo '=========================================='
  echo '✅ LINUX DRILL COMPLETED SUCCESSFULLY!'
  echo '=========================================='
"
