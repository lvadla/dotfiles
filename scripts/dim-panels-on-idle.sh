#!/usr/bin/env bash
set -euo pipefail

# Only handle external monitors via ddcutil
command -v ddcutil >/dev/null 2>&1 || exit 0

# Don’t fight the lock screen (some setups emit a “resume” when the locker starts)
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

# Debounce: skip if we just dimmed within 1s
STAMP="$STATE_DIR/dim.stamp"
now=$(date +%s)
if [[ -f "$STAMP" && $((now - $(cat "$STAMP"))) -lt 1 ]]; then
  exit 0
fi

: > "$BR_FILE"

# Helper: list displays robustly
mapfile -t DISPLAYS < <(ddcutil detect 2>/dev/null | awk '/Display/ {print $2}')

for disp in "${DISPLAYS[@]}"; do
  # Read current brightness (VCP 0x10)
  cur=$(ddcutil --display "$disp" getvcp 10 2>/dev/null | awk '/current value/ {match($0, /= *([0-9]+)/, arr); print arr[1]}')
  [[ -n "${cur:-}" ]] && echo "${disp}:${cur}" >> "$BR_FILE"
  # Dim to 10 (tweak to taste)
  ddcutil --display "$disp" setvcp 10 10 >/dev/null 2>&1 || true
  echo "Dimming external monitor ${disp} (saved brightness: ${cur:-unknown})"
done

echo "$now" > "$STAMP"
