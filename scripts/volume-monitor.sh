#!/usr/bin/env bash
#
# Monitor volume changes and invoke volume-change.sh script
# Uses pw-mon to detect changes to the default audio sink

set -eu

# Path to the volume change script
SCRIPT_DIR="$(dirname "$0")"
VOLUME_SCRIPT="$SCRIPT_DIR/volume-change.sh"

# Function to get current default sink's parent device ID
get_default_sink_device_id() {
    wpctl inspect @DEFAULT_AUDIO_SINK@ | grep "device.id" | awk -F'"' '{print $2}'
}

echo "Starting volume monitor..."
echo "Volume script: $VOLUME_SCRIPT"

# Store previous volume and mute state to detect actual changes
prev_volume=""
prev_mute=""
# Monitor events using complete event blocks
pw-mon -opa | while IFS= read -r line; do
    # Start of a new event block when we see "changed:"
    if [[ "$line" == "changed:" ]]; then
        # Read the next line which should contain the device ID
        IFS= read -r id_line
        if device_id=$(echo "$id_line" | grep -o 'id: [0-9]*' | awk '{print $2}'); then
            # Check if this device ID matches our current default sink's device
            current_default_device=$(get_default_sink_device_id)
            if [[ "$device_id" == "$current_default_device" ]]; then
                echo "Volume change detected on device $device_id"
                # Get current volume info
        volume_info=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
                volume=$(echo "$volume_info" | awk '{print $2}')

                # Skip processing if we can't get volume info
                if [[ -z "$volume_info" ]] || [[ "$volume_info" == *"error"* ]]; then
                    echo "Warning: Could not get volume info: $volume_info"
                    continue
                fi

        # Check if muted (MUTED appears in output when muted)
        if echo "$volume_info" | grep -q "MUTED"; then
            is_muted="true"
        else
            is_muted="false"
        fi

        # Only trigger script if volume or mute state actually changed
        if [[ "$volume" != "$prev_volume" ]] || [[ "$is_muted" != "$prev_mute" ]]; then
            echo "Volume changed: $volume (muted: $is_muted)"

            # Convert volume to percentage for logging
            if [[ -n "$volume" ]]; then
                volume_percent=$(awk "BEGIN {print int($volume*100)}")
                echo "Volume: ${volume_percent}%"
            else
                echo "Warning: Empty volume value detected"
            fi

            # Determine what type of change occurred
            action=""
            if [[ -z "$prev_volume" ]]; then
                # First run, don't trigger any action
                echo "Initial volume state detected, no action needed"
            elif [[ "$is_muted" != "$prev_mute" ]]; then
                action="mute"
            elif [[ -n "$volume" ]] && [[ -n "$prev_volume" ]]; then
                # Compare volumes using awk for float comparison
                vol_diff=$(awk "BEGIN {print $volume - $prev_volume}")
                if awk "BEGIN {exit !($vol_diff > 0.01)}"; then
                    action="raise"
                elif awk "BEGIN {exit !($vol_diff < -0.01)}"; then
                    action="lower"
                fi
            else
                echo "Warning: Cannot compare volumes - current: '$volume', previous: '$prev_volume'"
            fi

            if [[ -n "$action" ]] && [[ -x "$VOLUME_SCRIPT" ]]; then
                echo "Running volume script with action: $action"
                "$VOLUME_SCRIPT" "$action" &
            elif [[ ! -x "$VOLUME_SCRIPT" ]]; then
                echo "Warning: $VOLUME_SCRIPT is not executable"
            else
                echo "Could not determine volume change action"
            fi

            prev_volume="$volume"
            prev_mute="$is_muted"
                fi
            fi
        fi
    fi
done
