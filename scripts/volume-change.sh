#!/bin/sh
# volume-change.sh
# Usage: volume-change.sh [raise|lower|mute]

if [ -z "$1" ]; then
    echo "Usage: $0 [raise|lower|mute]"
    exit 1
fi

# Get current volume for display
VOLUME_INFO=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
VOLUME=$(echo "$VOLUME_INFO" | awk '{print $2}')
VOLUME_PERCENT=$(awk "BEGIN {print int($VOLUME*100)}")

case "$1" in
    raise|lower)
        paplay /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga &
        if echo "$VOLUME_INFO" | grep -q "MUTED"; then
            swayosd-client --custom-icon "audio-volume-muted-symbolic" --custom-progress "$(awk "BEGIN {print $VOLUME}")" --custom-progress-text "${VOLUME_PERCENT}% (Muted)"
        else
            if awk "BEGIN {exit !($VOLUME >= 0.67)}"; then
                ICON="audio-volume-high-symbolic"
            elif awk "BEGIN {exit !($VOLUME >= 0.33)}"; then
                ICON="audio-volume-medium-symbolic"
            else
                ICON="audio-volume-low-symbolic"
            fi
            swayosd-client --custom-icon "$ICON" --custom-progress "$(awk "BEGIN {print $VOLUME}")" --custom-progress-text "${VOLUME_PERCENT}%"
        fi
        ;;
    mute)
        paplay /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga &
        if echo "$VOLUME_INFO" | grep -q "MUTED"; then
            swayosd-client --custom-icon "audio-volume-muted-symbolic" --custom-progress "$(awk "BEGIN {print $VOLUME}")" --custom-progress-text "${VOLUME_PERCENT}% (Muted)"
        else
            if awk "BEGIN {exit !($VOLUME >= 0.67)}"; then
                ICON="audio-volume-high-symbolic"
            elif awk "BEGIN {exit !($VOLUME >= 0.33)}"; then
                ICON="audio-volume-medium-symbolic"
            else
                ICON="audio-volume-low-symbolic"
            fi
            swayosd-client --custom-icon "$ICON" --custom-progress "$(awk "BEGIN {print $VOLUME}")" --custom-progress-text "${VOLUME_PERCENT}%"
        fi
        ;;
    *)
        echo "Invalid argument: $1"
        echo "Usage: $0 [raise|lower|mute]"
        exit 1
        ;;
esac
