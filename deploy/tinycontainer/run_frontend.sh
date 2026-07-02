#!/usr/bin/env bash
# Serve frontend static files inside isolated container
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TC_DIR="$ROOT_DIR/packages/tinycontainer/shell_version"
ROOTFS="$TC_DIR/rootfs"
FRONTEND_DIST="$ROOT_DIR/frontend/dist"

if [[ ! -d "$ROOTFS/bin" ]]; then
  echo "Run setup_rootfs.sh first."
  exit 1
fi

if [[ ! -d "$FRONTEND_DIST" ]]; then
  echo "Build frontend first: cd frontend && npm run build"
  exit 1
fi

mkdir -p "$ROOTFS/opt/tinystack/web"
cp -r "$FRONTEND_DIST"/* "$ROOTFS/opt/tinystack/web/"

echo "Starting tinystack-web..."

sudo unshare --pid --mount --uts --net --fork chroot "$ROOTFS" /bin/sh -c "
  hostname tinystack-web
  mount -t proc proc /proc 2>/dev/null || true
  cd /opt/tinystack/web
  echo 'Static files at /opt/tinystack/web. Use python -m http.server 8080 or nginx if available.'
  exec /bin/sh
" &

WEB_PID=$!
echo "Web container PID: $WEB_PID"
echo "Attach with: sudo nsenter --target $WEB_PID --pid --mount --uts --net /bin/sh"
