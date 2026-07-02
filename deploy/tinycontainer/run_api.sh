#!/usr/bin/env bash
# Start TinyStack API inside Alpine chroot (PID/Mount/UTS isolation; host network)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

tinystack_require_rootfs
tinystack_ensure_dirs

if tinystack_is_running api; then
  tinystack_log "API already running (pid $(tinystack_read_pid api))"
  exit 0
fi

tinystack_bind_platform

tinystack_log "Starting tinystack-api on port ${API_PORT}..."

tinystack_sudo unshare --pid --mount --uts --fork chroot "$ROOTFS" /bin/sh -c "
  set -e
  hostname tinystack-api
  mount -t proc proc /proc
  export TINYSTACK_DATA_DIR=/opt/tinystack/data
  export TINYSTACK_LLM_URL=http://127.0.0.1:${LLM_PORT}
  export PYTHONPATH=/opt/tinystack/services/api:/opt/tinystack/packages/minirdb
  cd /opt/tinystack/services/api
  exec python3 -m uvicorn main:app --host 0.0.0.0 --port ${API_PORT}
" >"$LOG_DIR/api.log" 2>&1 &

API_PID=$!
sleep 1
tinystack_save_pid api "$API_PID"

if tinystack_wait_http "http://127.0.0.1:${API_PORT}/health" 60; then
  tinystack_log "API ready (pid ${API_PID})"
else
  tinystack_log "WARN: API health check timed out. See $LOG_DIR/api.log"
fi

echo "API PID: $API_PID"
echo "Attach: sudo nsenter --target $API_PID --pid --mount --uts /bin/sh"
