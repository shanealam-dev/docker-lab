#!/usr/bin/env bash
set -e

echo "=========================================="
echo "🚀 LAB 04: NETWORKING & ISOLATION DRILL"
echo "=========================================="

echo ""
echo "[Step 1] Creating isolated networks (web-tier, data-tier)..."
docker network create web-tier > /dev/null
docker network create data-tier > /dev/null

echo ""
echo "[Step 2] Launching private Redis on data-tier..."
docker run -d --name private-redis --network data-tier redis:7-alpine > /dev/null

echo ""
echo "[Step 3] Launching public client on web-tier..."
docker run -d --name public-client --network web-tier alpine sleep 100 > /dev/null

echo ""
echo "[Step 4] Proving isolation: public-client trying to reach private-redis..."
if docker exec public-client ping -c 1 -W 1 private-redis > /dev/null 2>&1; then
  echo "ERROR: Should NOT have reached private-redis!"
  exit 1
else
  echo "🔒 CONFIRMED: private-redis is UNREACHABLE from web-tier as expected!"
fi

echo ""
echo "[Step 5] Launching api-gateway on web-tier..."
docker run -d --name api-gateway --network web-tier alpine sleep 100 > /dev/null

echo ""
echo "[Step 6] Connecting api-gateway to data-tier as well..."
docker network connect data-tier api-gateway

echo ""
echo "[Step 7] Testing dual-network routing from api-gateway..."
docker exec api-gateway ping -c 1 public-client > /dev/null
echo "✅ api-gateway can reach public-client on web-tier!"

docker exec api-gateway ping -c 1 private-redis > /dev/null
echo "✅ api-gateway can reach private-redis on data-tier!"

echo ""
echo "[Step 8] 🧹 Cleaning up..."
docker rm -f private-redis public-client api-gateway > /dev/null
docker network rm web-tier data-tier > /dev/null

echo ""
echo "=========================================="
echo "✅ LAB 04 DRILL COMPLETED SUCCESSFULLY!"
echo "You mastered DNS resolution and multi-tier DMZ isolation."
echo "=========================================="
