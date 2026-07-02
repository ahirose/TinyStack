#!/usr/bin/env bash
# Start TinyStack API inside an isolated container (step4+ namespaces)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TC_DIR="$ROOT_DIR/packages/tinycontainer/shell_version"
ROOTFS="$TC_DIR/rootfs"
DATA_DIR="$ROOT_DIR/data"
API_PORT="${TINYSTACK_API_PORT:-8000}"

if [[ ! -d "$ROOTFS/bin" ]]; then
  echo "Run setup_rootfs.sh first."
  exit 1
fi

mkdir -p "$DATA_DIR"

echo "Starting tinystack-api on port $API_PORT (host namespace helper)..."

sudo unshare --pid --mount --uts --net --fork chroot "$ROOTFS" /bin/sh -c "
  hostname tinystack-api
  mount -t proc proc /proc 2>/dev/null || true
  export TINYSTACK_DATA_DIR='$DATA_DIR'
  export PATH=/usr/local/bin:/usr/bin:/bin
  echo 'API container ready. Run Python uvicorn from /opt/tinystack if installed.'
  exec /bin/sh
" &

API_PID=$!
sleep 1
echo "Container shell PID: $API_PID"
echo "Attach with: sudo nsenter --target $API_PID --pid --mount --uts --net /bin/sh"
