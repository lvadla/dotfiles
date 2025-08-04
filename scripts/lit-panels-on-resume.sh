BRIGHTNESS_FILE="/tmp/monitor_brightness_backup"

if [ -f "$BRIGHTNESS_FILE" ]; then
    while IFS=':' read -r disp brightness; do
        if [ -n "$disp" ] && [ -n "$brightness" ]; then
            ddcutil --display $disp setvcp 10 $brightness
            echo "Restoring external monitor $disp to brightness: $brightness"
        fi
    done < "$BRIGHTNESS_FILE"
else
    for disp in $(ddcutil detect | grep "Display" | awk '{print $2}'); do
        ddcutil --display $disp setvcp 10 50
        echo "Brightening external monitor $disp to default (50)"
    done
fi

