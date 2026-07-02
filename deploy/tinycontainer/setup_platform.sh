#!/usr/bin/env bash
# TinyStack platform setup for TinyContainer rootfs
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TC_ROOTFS="${TINYCONTAINER_ROOTFS:-$ROOT_DIR/packages/tinycontainer/shell_version/rootfs}"

echo "TinyStack: preparing platform in rootfs at $TC_ROOTFS"
echo "Run packages/tinycontainer/shell_version/setup_rootfs.sh first if rootfs is missing."

if [[ ! -d "$TC_ROOTFS/bin" ]]; then
  echo "Error: rootfs not found. Execute:"
  echo "  cd $ROOT_DIR/packages/tinycontainer/shell_version && ./setup_rootfs.sh"
  exit 1
fi

mkdir -p "$TC_ROOTFS/opt/tinystack"
cp -r "$ROOT_DIR/services" "$ROOT_DIR/bootstrap" "$ROOT_DIR/packages" "$ROOT_DIR/pyproject.toml" "$TC_ROOTFS/opt/tinystack/" 2>/dev/null || true

echo "Platform files copied to /opt/tinystack inside rootfs."
echo "Install Python deps inside container before starting API."
