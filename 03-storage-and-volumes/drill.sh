#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "🚀 LAB 03: PERSISTENCE & STORAGE DRILL"
echo "=========================================="

echo ""
echo "[Step 1] Creating named volume 'pg_hero_data'..."
docker volume create pg_hero_data > /dev/null

echo ""
echo "[Step 2] Launching PostgreSQL container (pg-server)..."
docker run -d --name pg-server \
  -e POSTGRES_PASSWORD=supersecret \
  -e POSTGRES_DB=herodb \
  -v pg_hero_data:/var/lib/postgresql/data \
  -p 5432:5432 postgres:16-alpine > /dev/null

echo "Waiting for Postgres to become ready..."
until docker exec pg-server pg_isready -U postgres > /dev/null 2>&1; do
  sleep 1
done
echo "Postgres is READY!"

echo ""
echo "[Step 3] Creating table and inserting test data..."
docker exec -i pg-server psql -U postgres -d herodb << 'EOF' > /dev/null
CREATE TABLE heroes (id SERIAL PRIMARY KEY, name VARCHAR(50), superpower VARCHAR(50));
INSERT INTO heroes (name, superpower) VALUES ('Shane', 'Docker Hero'), ('Batman', 'Prep Time');
EOF

echo "Data written to database inside pg-server:"
docker exec -i pg-server psql -U postgres -d herodb -c "SELECT * FROM heroes;"

echo ""
echo "[Step 4] 💥 DESTROYING CONTAINER (docker rm -f pg-server)..."
docker rm -f pg-server > /dev/null
echo "Container is completely gone!"

echo ""
echo "[Step 5] 🐣 SPINNING UP BRAND NEW CONTAINER (pg-server-v2) WITH SAME VOLUME..."
docker run -d --name pg-server-v2 \
  -e POSTGRES_PASSWORD=supersecret \
  -e POSTGRES_DB=herodb \
  -v pg_hero_data:/var/lib/postgresql/data \
  -p 5432:5432 postgres:16-alpine > /dev/null

until docker exec pg-server-v2 pg_isready -U postgres > /dev/null 2>&1; do
  sleep 1
done

echo ""
echo "[Step 6] 🔍 QUERYING NEW CONTAINER FOR PERSISTED DATA:"
docker exec -i pg-server-v2 psql -U postgres -d herodb -c "SELECT * FROM heroes;"

echo ""
echo "[Step 7] 📦 BACKING UP VOLUME TO TARBALL ON MAC..."
docker run --rm \
  -v pg_hero_data:/source_data:ro \
  -v "$DIR":/backup \
  alpine tar czf /backup/pg_backup.tar.gz -C /source_data .
echo "Backup created at $DIR/pg_backup.tar.gz ($(du -h "$DIR/pg_backup.tar.gz" | cut -f1))"

echo ""
echo "[Step 8] 🧹 CLEANING UP CONTAINERS & VOLUMES..."
docker rm -f pg-server-v2 > /dev/null
docker volume rm pg_hero_data > /dev/null
rm -f "$DIR/pg_backup.tar.gz"

echo ""
echo "=========================================="
echo "✅ LAB 03 DRILL COMPLETED SUCCESSFULLY!"
echo "Proof: Data survived container destruction!"
echo "=========================================="
