#!/usr/bin/env bash
# Start full TinyStack platform on TinyContainer (LLM + API + Web)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

tinystack_log "Launching TinyStack on TinyContainer..."
tinystack_require_rootfs
tinystack_ensure_dirs

if [[ "${1:-}" == "--force" ]]; then
  tinystack_stop_all
elif tinystack_is_running llm || tinystack_is_running api || tinystack_is_running web; then
  tinystack_log "Some services already running. Use stop_all.sh first or pass --force"
  "$SCRIPT_DIR/status.sh" || true
  exit 1
fi

cleanup() {
  tinystack_log "Shutting down TinyStack..."
  tinystack_stop_all
}
trap cleanup EXIT INT TERM

"$SCRIPT_DIR/run_llm.sh"
sleep 2
"$SCRIPT_DIR/run_api.sh"
sleep 2
"$SCRIPT_DIR/run_frontend.sh"

tinystack_print_urls

tinystack_log "All services started. Press Ctrl+C to stop."

# Disable trap-based cleanup on normal wait - user uses stop_all or Ctrl+C
while true; do
  sleep 5
  for svc in llm api web; do
    if ! tinystack_is_running "$svc"; then
      tinystack_log "ERROR: ${svc} exited unexpectedly. Check $LOG_DIR/${svc}.log"
      exit 1
    fi
  done
done
