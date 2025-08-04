BRIGHTNESS_FILE="/tmp/monitor_brightness_backup"
rm -f "$BRIGHTNESS_FILE"

for disp in $(ddcutil detect | grep "Display" | awk '{print $2}'); do
    current_brightness=$(ddcutil --display $disp getvcp 10 2>/dev/null | grep -o 'current value =[ ]*[0-9]*' | grep -o '[0-9]*$')
    echo "$disp:$current_brightness" >> "$BRIGHTNESS_FILE"
    ddcutil --display $disp setvcp 10 10
    echo "Dimming external monitor $disp (saved brightness: $current_brightness)"
done

