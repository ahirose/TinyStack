#!/usr/bin/env bash
# Start nginx static frontend inside Alpine chroot (proxies /api to host API)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

tinystack_require_rootfs
tinystack_ensure_dirs

if tinystack_is_running web; then
  tinystack_log "Web already running (pid $(tinystack_read_pid web))"
  exit 0
fi

if [[ ! -f "$ROOTFS/opt/tinystack/web/index.html" ]]; then
  tinystack_log "WARN: frontend not built. Run setup_platform.sh first."
fi

tinystack_log "Starting tinystack-web on port ${WEB_PORT}..."

tinystack_sudo unshare --pid --mount --uts --fork chroot "$ROOTFS" /bin/sh -c "
  set -e
  hostname tinystack-web
  mount -t proc proc /proc
  exec nginx -g 'daemon off;'
" >"$LOG_DIR/web.log" 2>&1 &

WEB_PID=$!
sleep 1
tinystack_save_pid web "$WEB_PID"

if tinystack_wait_http "http://127.0.0.1:${WEB_PORT}/" 30; then
  tinystack_log "Web ready (pid ${WEB_PID})"
else
  tinystack_log "WARN: Web health check timed out. See $LOG_DIR/web.log"
fi

echo "Web PID: $WEB_PID"
echo "Attach: sudo nsenter --target $WEB_PID --pid --mount --uts /bin/sh"
