#!/usr/bin/env bash
# TinyStack multi-container launcher (extends TinyContainer step7)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COUNT="${1:-3}"

echo "TinyStack: launching platform containers (pattern from step7_multi_container.sh)"
echo "Requires Linux or WSL2 with sudo."

"$SCRIPT_DIR/setup_platform.sh" || true

PIDS=()

start_container() {
  local name="$1"
  local script="$2"
  echo "--- Starting $name ---"
  "$script" &
  PIDS+=($!)
  sleep 1
}

start_container "tinystack-api" "$SCRIPT_DIR/run_api.sh"
start_container "tinystack-llm" "$SCRIPT_DIR/run_llm.sh"
start_container "tinystack-web" "$SCRIPT_DIR/run_frontend.sh"

echo ""
echo "Started ${#PIDS[@]} containers."
echo "PIDs: ${PIDS[*]}"
echo ""
echo "Exercise: attach to each container with nsenter:"
for pid in "${PIDS[@]}"; do
  echo "  sudo nsenter --target $pid --pid --mount --uts --net /bin/sh"
done
echo ""
echo "Press Ctrl+C to stop (containers may need manual cleanup)."

wait
