#!/usr/bin/env bash
# Start TinyLLM inference worker container with cgroup memory limit (step6 pattern)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TC_DIR="$ROOT_DIR/packages/tinycontainer/shell_version"
ROOTFS="$TC_DIR/rootfs"
CGROUP_NAME="tinystack_llm"
MEMORY_LIMIT="${TINYSTACK_LLM_MEMORY:-512M}"

if [[ ! -d "$ROOTFS/bin" ]]; then
  echo "Run setup_rootfs.sh first."
  exit 1
fi

echo "Starting tinystack-llm with memory limit $MEMORY_LIMIT..."

sudo unshare --pid --mount --uts --net --fork chroot "$ROOTFS" /bin/sh -c "
  hostname tinystack-llm
  mount -t proc proc /proc 2>/dev/null || true
  echo 'LLM container ready. Load TinyLLM model from /opt/tinystack/packages/tinyllm.'
  exec /bin/sh
" &

LLM_PID=$!

if [[ -d /sys/fs/cgroup ]]; then
  CGROUP_PATH="/sys/fs/cgroup/$CGROUP_NAME"
  sudo mkdir -p "$CGROUP_PATH" 2>/dev/null || true
  if [[ -f "$CGROUP_PATH/memory.max" ]]; then
    echo "$MEMORY_LIMIT" | sudo tee "$CGROUP_PATH/memory.max" >/dev/null
    echo "$LLM_PID" | sudo tee "$CGROUP_PATH/cgroup.procs" >/dev/null 2>/dev/null || true
    echo "Applied cgroup v2 memory limit to PID $LLM_PID"
  fi
fi

echo "LLM container PID: $LLM_PID"
echo "Attach with: sudo nsenter --target $LLM_PID --pid --mount --uts --net /bin/sh"
