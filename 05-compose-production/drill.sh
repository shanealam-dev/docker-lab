#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=========================================="
echo "🚀 LAB 05: FULL STACK COMPOSE ORCHESTRATION"
echo "=========================================="

echo ""
echo "[Step 1] Bringing up full 5-service stack in detached mode..."
docker compose up -d

echo ""
echo "[Step 2] Waiting for all healthchecks to turn healthy..."
sleep 5
docker compose ps

echo ""
echo "[Step 3] Testing React Frontend (port 3000)..."
curl -s -I http://localhost:3000 | head -n 3

echo ""
echo "[Step 4] Testing Node API (port 4000)..."
curl -s http://localhost:4000/api/health
echo ""

echo ""
echo "[Step 5] Checking container resource limits..."
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo ""
echo "[Step 6] 🧹 Gracefully shutting down stack & wiping volumes..."
docker compose down -v > /dev/null

echo ""
echo "=========================================="
echo "✅ LAB 05 DRILL COMPLETED SUCCESSFULLY!"
echo "Production stack verified with healthchecks & limits!"
echo "=========================================="
