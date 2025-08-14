#!/usr/bin/env bash
set -euo pipefail

command -v ddcutil >/dev/null 2>&1 || exit 0

# If lock screen is still up, wait until after unlock
if pgrep -x hyprlock >/dev/null; then
  exit 0
fi

USER_ID="$(id -u)"
STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/${USER_ID}}/hypridle-ddc"
mkdir -p "$STATE_DIR"
BR_FILE="$STATE_DIR/monitor_brightness_backup"
LOCK="$STATE_DIR/lock"

# Serialize to avoid overlapping runs
exec 9>"$LOCK"
flock -n 9 || exit 0

# Belt-and-suspenders: ensure DPMS is on and give monitors a beat to wake
hyprctl dispatch dpms on >/dev/null 2>&1 || true
sleep 0.2

if [[ -f "$BR_FILE" ]]; then
  # Restore saved per-display levels
  while IFS=':' read -r disp brightness; do
    [[ -n "${disp:-}" && -n "${brightness:-}" ]] || continue
    ddcutil --display "$disp" setvcp 10 "$brightness" >/dev/null 2>&1 || true
    echo "Restored external monitor ${disp} to brightness: ${brightness}"
  done < "$BR_FILE"
  rm -f "$BR_FILE"
else
  # No backup found—apply a reasonable default
  mapfile -t DISPLAYS < <(ddcutil detect 2>/dev/null | awk '/Display/ {print $2}')
  for disp in "${DISPLAYS[@]}"; do
    ddcutil --display "$disp" setvcp 10 50 >/dev/null 2>&1 || true
    echo "Brightened external monitor ${disp} to default (50)"
  done
fi
