#!/bin/bash

# # spacebar settings
# SPACEBAR_HEIGHT=$(spacebar -m config height)
# yabai -m config external_bar all:$SPACEBAR_HEIGHT:0

# external display space settings
if grep -q 3440 <<< $(cscreen -l) ; then
    # 21:9 monitor - 100% scaling
    osascript ~/Scripts/show-menu-bar.scpt
    osascript ~/Scripts/show-dock.scpt
    yabai -m config top_padding                  16
    yabai -m config bottom_padding               16
    yabai -m config left_padding                 6
    yabai -m config right_padding                26
    yabai -m config window_gap                   8
elif grep -q 2752 <<< $(cscreen -l) ; then
    # 21:9 monitor - 125% scaling
    osascript ~/Scripts/show-menu-bar.scpt
    osascript ~/Scripts/show-dock.scpt
    yabai -m config top_padding                  16
    yabai -m config bottom_padding               16
    yabai -m config left_padding                 6
    yabai -m config right_padding                26
    yabai -m config window_gap                   8
elif grep -q 2293 <<< $(cscreen -l) ; then
    # 21:9 monitor - 150% scaling
    osascript ~/Scripts/show-menu-bar.scpt
    osascript ~/Scripts/hide-dock.scpt
    yabai -m config top_padding                  16
    yabai -m config bottom_padding               16
    yabai -m config left_padding                 26
    yabai -m config right_padding                26
    yabai -m config window_gap                   8
elif grep -q 1720 <<< $(cscreen -l) ; then
    # 21:9 monitor - 200% scaling
    osascript ~/Scripts/show-menu-bar.scpt
    osascript ~/Scripts/hide-dock.scpt
    yabai -m config top_padding                  9
    yabai -m config bottom_padding               9
    yabai -m config left_padding                 9
    yabai -m config right_padding                9
    yabai -m config window_gap                   5
elif grep -q 2560 <<< $(cscreen -l) ; then
    # 16:9 monitor - 100% scaling
    osascript ~/Scripts/show-menu-bar.scpt
    osascript ~/Scripts/hide-dock.scpt
    yabai -m config top_padding                  16
    yabai -m config bottom_padding               16
    yabai -m config left_padding                 16
    yabai -m config right_padding                16
    yabai -m config window_gap                   16
elif grep -q 2048 <<< $(cscreen -l) ; then
    # 16:9 monitor - 125% scaling
    osascript ~/Scripts/show-menu-bar.scpt
    osascript ~/Scripts/hide-dock.scpt
    yabai -m config top_padding                  16
    yabai -m config bottom_padding               16
    yabai -m config left_padding                 16
    yabai -m config right_padding                16
    yabai -m config window_gap                   16
elif grep -q 1707 <<< $(cscreen -l) ; then
    # 16:9 monitor - 150% scaling
    osascript ~/Scripts/show-menu-bar.scpt
    osascript ~/Scripts/hide-dock.scpt
    yabai -m config top_padding                  16
    yabai -m config bottom_padding               16
    yabai -m config left_padding                 16
    yabai -m config right_padding                16
    yabai -m config window_gap                   16
else
    # built-in display space settings
    osascript ~/Scripts/hide-menu-bar.scpt
    osascript ~/Scripts/hide-dock.scpt
    yabai -m config top_padding                  7
    yabai -m config bottom_padding               7
    yabai -m config left_padding                 7
    yabai -m config right_padding                7
    yabai -m config window_gap                   7
fi

if defaults read -g AppleInterfaceStyle &>/dev/null ; then
    yabai -m config normal_window_border_color   0xff404552 # dark gray
else
    yabai -m config normal_window_border_color   0xffCCCCCC # gray
fi

yabai -m config active_window_border_color   0xff65B84D # green
yabai -m config insert_feedback_color        0xffd75f5f # red

defaults write -g AppleAccentColor 3                    # green
defaults write -g AppleHighlightColor "0.752941 0.964706 0.678431 Green"

# 0xff5294e2 - blue
# 0xff3A9EDD - blue (slack)
# 0xff65B84D - green
# 0xffE49C6A - orange
# 0xffED609C - pink
# 0xff78327C - purple
# 0xffF6BB3B - yellow
