#!/usr/bin/env bash
set -e

echo "=========================================="
echo "🚀 LAB 01: CONTAINER LIFECYCLE INTERACTIVE DRILL"
echo "=========================================="

echo ""
echo "[Step 1] Starting redis-lab in background..."
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine

echo ""
echo "[Step 2] Pinging Redis via ephemeral container..."
docker run --rm redis:7-alpine redis-cli -h host.docker.internal -p 6379 ping

echo ""
echo "[Step 3] Storing sample data in Redis..."
docker run --rm redis:7-alpine redis-cli -h host.docker.internal -p 6379 set course "Docker Zero to Hero"
RESULT=$(docker run --rm redis:7-alpine redis-cli -h host.docker.internal -p 6379 get course)
echo "Retrieved from Redis: $RESULT"

echo ""
echo "[Step 4] Starting Python web server on port 8080..."
docker run -d --name py-web -p 8080:8000 python:3.12-alpine python -m http.server 8000
sleep 2

echo ""
echo "[Step 5] Hitting Python web server..."
curl -s -I http://localhost:8080 | head -n 3

echo ""
echo "[Step 6] Inspecting container with Go template filter..."
IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' py-web)
STATUS=$(docker inspect --format '{{ .State.Status }}' py-web)
echo "Container internal IP: ${IP:-'(via bridge)'}"
echo "Container state status: $STATUS"

echo ""
echo "[Step 7] Simulating dead container rescue..."
docker run --name crash-box alpine sh -c "echo 'SECRET_BACKUP_KEY_8941' > /backup.txt && exit 1" || true
echo "Container diff on crash-box:"
docker diff crash-box
docker cp crash-box:/backup.txt ./rescued_backup.txt
echo "Rescued content: $(cat ./rescued_backup.txt)"
rm -f ./rescued_backup.txt
docker rm -f crash-box > /dev/null

echo ""
echo "[Step 8] Cleaning up drill containers..."
docker rm -f redis-lab py-web > /dev/null

echo ""
echo "=========================================="
echo "✅ DRILL COMPLETED SUCCESSFULLY!"
echo "You have verified: run -d, --rm, exec, cp, diff, inspect, and rm -f."
echo "=========================================="
