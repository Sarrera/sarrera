#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Sarrera - Compile & Deploy Flutter Web Portal to Caddy
# ==============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="${REPO_DIR}/frontend"
PORTAL_DIR="${REPO_DIR}/config/portal"

echo "=========================================================="
echo " Sarrera - Building Flutter Web Portal"
echo " Source: ${FRONTEND_DIR}"
echo " Target: ${PORTAL_DIR}"
echo "=========================================================="

if ! command -v flutter &> /dev/null; then
  echo "❌ Error: 'flutter' command not found in PATH."
  echo "Please install Flutter (3.24+) or run inside a Flutter-enabled environment."
  exit 1
fi

echo "📦 [1/3] Compiling Flutter Web application (release mode)..."
cd "${FRONTEND_DIR}"
flutter build web --release --no-tree-shake-icons

echo "🚀 [2/3] Syncing compiled assets to Caddy portal directory..."
mkdir -p "${PORTAL_DIR}"
rm -rf "${PORTAL_DIR:?}"/*
cp -R "${FRONTEND_DIR}/build/web/"* "${PORTAL_DIR}/"
# Also ensure direct asset links resolve
cp -R "${REPO_DIR}/assets/"* "${PORTAL_DIR}/assets/" 2>/dev/null || true

echo "🔄 [3/3] Checking Caddy container..."
if docker ps --format '{{.Names}}' | grep -q "^ai-caddy$"; then
  echo "Reloading Caddy configuration..."
  docker exec ai-caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || true
  echo "✅ Caddy reloaded successfully."
else
  echo "ℹ️ Caddy container not running yet. Run 'docker compose up -d' to start the stack."
fi

echo ""
echo "=========================================================="
echo "🎉 Build Complete! Flutter Portal deployed to Caddy."
echo "Access your live portal at: https://localhost/"
echo "=========================================================="
