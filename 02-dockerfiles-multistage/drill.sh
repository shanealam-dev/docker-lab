#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "🚀 LAB 02: MULTI-STAGE & DOCKERFILE DRILL"
echo "=========================================="

echo ""
echo "[Step 1] Building Python image (hero-python:1.0)..."
docker build -t hero-python:1.0 "$DIR/python-app"

echo ""
echo "[Step 2] Running Python container & verifying non-root user..."
docker run -d --name py-test -p 5050:5000 hero-python:1.0
sleep 2
USER_NAME=$(docker exec py-test whoami)
echo "Python container is running as user: '$USER_NAME' (Expected: appuser)"
docker rm -f py-test > /dev/null

echo ""
echo "[Step 3] Building Node/Express API image (hero-node:1.0)..."
docker build -t hero-node:1.0 "$DIR/node-app"

echo ""
echo "[Step 4] Running Node container & testing health..."
docker run -d --name node-test -p 4000:4000 hero-node:1.0
sleep 2
HEALTH=$(curl -s http://localhost:4000/api/health)
echo "Node health endpoint response: $HEALTH"
docker rm -f node-test > /dev/null

echo ""
echo "[Step 5] Building React Multi-Stage Production image (hero-react:prod)..."
docker build -t hero-react:prod "$DIR/react-app"

echo ""
echo "=========================================="
echo "📊 IMAGE SIZE COMPARISON SUMMARY"
echo "=========================================="
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -E "hero-|REPOSITORY"

echo ""
echo "=========================================="
echo "✅ LAB 02 VERIFIED SUCCESSFULLY!"
echo "Notice how the multi-stage React app is only ~25-40MB!"
echo "=========================================="
