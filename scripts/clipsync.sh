#!/usr/bin/env sh
# Clipboard synchronization from X11 -> Wayland.
# Requires: wl-clipboard, xclip, clipnotify.

insert() {
  value=$(cat)
  wValue="$(wl-paste)"
  xValue="$(xclip -o -selection clipboard)"
  if [ "$value" != "$wValue" ]; then
    echo -n "$value" | wl-copy
  fi
  if [ "$value" != "$xValue" ]; then
    echo -n "$value" | xclip -selection clipboard
  fi
}

watch() {
  # X11 → Wayland
  while clipnotify; do
    xclip -o -selection clipboard | "$(realpath $0)" insert
  done &
}

kill() {
  pkill wl-paste
  pkill clipnotify
  pkill xclip
  pkill clipsync.sh
}

"$@"
