#!/bin/bash

if grep -q 1440 <<< $(cscreen -l) ; then
    # external HDPI display
    /usr/local/bin/yabai -m config top_padding                  40
    /usr/local/bin/yabai -m config bottom_padding               25
    /usr/local/bin/yabai -m config left_padding                 75
    /usr/local/bin/yabai -m config right_padding                75
    /usr/local/bin/yabai -m config window_gap                   25

    spacebar -m config spacing_left       35
    spacebar -m config spacing_right      35
    spacebar -m config text_font          "JetBrainsMono Nerd Font:Regular:16.0"
    spacebar -m config icon_font          "JetBrainsMono Nerd Font:Bold:22.0"
else
    # built-in display
    /usr/local/bin/yabai -m config top_padding                  5
    /usr/local/bin/yabai -m config bottom_padding               5
    /usr/local/bin/yabai -m config left_padding                 5
    /usr/local/bin/yabai -m config right_padding                5
    /usr/local/bin/yabai -m config window_gap                   5

    spacebar -m config spacing_left       25
    spacebar -m config spacing_right      25
    spacebar -m config text_font          "JetBrainsMono Nerd Font:Regular:12.0"
    spacebar -m config icon_font          "JetBrainsMono Nerd Font:Bold:16.0"
fi
