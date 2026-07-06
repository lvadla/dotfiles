#!/bin/bash
ON_TEMP=3500
OFF_TEMP=6500

# Query the current temperature
CURRENT_TEMP=$(hyprctl hyprsunset temperature 2>/dev/null | grep -oE '[0-9]+')
if [[ "$CURRENT_TEMP" == "$OFF_TEMP" ]]; then
  hyprctl hyprsunset temperature $ON_TEMP
  notify-send "  Nightlight On"
  if grep -q "custom/nightlight" ~/.config/waybar/config.jsonc; then
  	pkill waybar
   	nohup waybar > ~/tmp/waybar.log 2>&1 &
  fi
else
  hyprctl hyprsunset temperature $OFF_TEMP
  notify-send "   Nightlight Off"
  if grep -q "custom/nightlight" ~/.config/waybar/config.jsonc; then
 	pkill waybar
  	nohup waybar > ~/tmp/waybar.log 2>&1 &
  fi
fi
