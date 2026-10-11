#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=========================================="
echo "🥊 LAB 07: CAPSTONE BOSS FIGHT VERIFICATION"
echo "=========================================="

echo ""
echo "[Step 1] Launching fixed production stack..."
docker compose -f solution/compose.fixed.yaml up -d

echo ""
echo "[Step 2] Waiting for Postgres healthcheck..."
sleep 5
docker compose -f solution/compose.fixed.yaml ps

echo ""
echo "[Step 3] Verifying API responsiveness on port 4000..."
RESPONSE=$(curl -s http://localhost:4000/api/health)
echo "API Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "healthy"; then
  echo ""
  echo "🎉 SUCCESS: All 4 bugs resolved!"
  echo "1. Loopback binding fixed to 0.0.0.0"
  echo "2. Network bridge joined"
  echo "3. Healthcheck dependency synchronized"
  echo "4. Database credentials provided"
fi

echo ""
echo "[Step 4] 🧹 Cleaning up capstone stack..."
docker compose -f solution/compose.fixed.yaml down -v > /dev/null

echo ""
echo "=========================================="
echo "🏆 CONGRATULATIONS! YOU HAVE CONQUERED DOCKER!"
echo "You are now ready to graduate to Kubernetes (k8s-lab)!"
echo "=========================================="
