#!/bin/bash

osascript -e "display notification \"AppleInterfaceStyle has changed...\" with title \"Nighthook\""

if defaults read -g AppleInterfaceStyle &>/dev/null; then
    MODE="dark"
else
    MODE="light"
fi

if [[  $MODE == "dark"  ]]; then
    spacebar -m config clock_icon_color 0xffa8a8a8
    spacebar -m config dnd_icon_color   0xffa8a8a8
    spacebar -m config foreground_color 0xffa8a8a8
    spacebar -m config background_color 0xff202020
elif [[  $MODE == "light"  ]]; then
    spacebar -m config clock_icon_color 0xff073642
    spacebar -m config dnd_icon_color   0xff073642
    spacebar -m config foreground_color 0xff073642
    spacebar -m config background_color 0xffeee8d5
fi