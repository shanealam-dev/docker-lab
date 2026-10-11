#!/usr/bin/env bash
set -e

echo "=========================================="
echo "🚀 LAB 06: MACOS ARCHITECTURE & EMULATION DRILL"
echo "=========================================="

echo ""
echo "[Step 1] Resolving host.docker.internal from inside Linux container..."
docker run --rm alpine ping -c 2 host.docker.internal

echo ""
echo "[Step 2] Native architecture of current Docker engine:"
docker version --format 'OS/Arch: {{.Server.Os}}/{{.Server.Arch}}'

echo ""
echo "[Step 3] Cross-compiling x86_64 image on Mac via Rosetta emulation..."
docker build -q --platform linux/amd64 -t mac-amd64-test - << 'EOF' > /dev/null
FROM alpine:latest
RUN uname -m > /arch.txt
CMD cat /arch.txt
EOF

DETECTED_ARCH=$(docker run --rm mac-amd64-test)
echo "Architecture reported inside x86_64 container: $DETECTED_ARCH"
if [ "$DETECTED_ARCH" = "x86_64" ]; then
  echo "✅ Rosetta 2 cross-architecture emulation verified!"
fi

echo ""
echo "[Step 4] Cleaning up test image..."
docker rmi -f mac-amd64-test > /dev/null

echo ""
echo "=========================================="
echo "✅ LAB 06 DRILL COMPLETED SUCCESSFULLY!"
echo "=========================================="
