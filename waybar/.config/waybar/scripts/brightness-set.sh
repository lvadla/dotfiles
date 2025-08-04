#!/bin/bash

# Set brightness to specific value
# Usage: brightness-set.sh <value> [search_terms]

if [ -z "$1" ]; then
    echo "Usage: $0 <brightness_value> [search_terms]"
    exit 1
fi

BRIGHTNESS_VALUE="$1"
SEARCH_TERMS="${2:-AW3423DWF\|UltraFine}"

CACHE_FILE="/tmp/waybar-brightness-buses"
CACHE_MAX_AGE=300  # 5 minutes

# Function to detect and cache bus numbers by model names
detect_buses() {
    local search_terms="$1"
    ddcutil detect --brief 2>/dev/null | \
    grep -B3 "$search_terms" | \
    grep "I2C bus" | grep -o '[0-9]\+$' > "$CACHE_FILE"
}

# Use cached buses if recent and not empty, otherwise detect
if [[ ! -f "$CACHE_FILE" ]] || [[ ! -s "$CACHE_FILE" ]] || [[ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE"))) -gt $CACHE_MAX_AGE ]]; then
    detect_buses "$SEARCH_TERMS"
fi

# Apply brightness changes to cached buses
while read -r bus_num; do
    if [[ -n "$bus_num" ]]; then
        ddcutil --noverify --bus "$bus_num" setvcp 10 "$BRIGHTNESS_VALUE" 2>/dev/null &
    fi
done < "$CACHE_FILE"
wait  # Wait for all background processes

# Refresh waybar
pkill -RTMIN+5 waybar