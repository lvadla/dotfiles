#!/bin/bash
# Detect terminal theme (dark/light)
# Priority: terminal query (OSC 11) → cache → system detection
# Output: "dark" or "light"

CACHE="/tmp/term-theme-$(id -u)"

# 1. Try terminal query via OSC 11 (uses /dev/tty directly so it works even when stdin is a pipe)
if [[ -c /dev/tty ]]; then
    old_settings=$(stty -F /dev/tty -g 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        stty -F /dev/tty raw -echo 2>/dev/null
        printf '\e]11;?\a' >/dev/tty
        read -t 0.02 -r -d $'\a' response </dev/tty
        stty -F /dev/tty "$old_settings" 2>/dev/null

        if [[ "$response" =~ rgb:([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+) ]]; then
            r=$((16#${BASH_REMATCH[1]:0:2}))
            g=$((16#${BASH_REMATCH[2]:0:2}))
            b=$((16#${BASH_REMATCH[3]:0:2}))
            luminance=$(( (2126 * r + 7152 * g + 722 * b) / 10000 ))
            result=$([[ $luminance -lt 128 ]] && echo "dark" || echo "light")
            echo "$result" | tee "$CACHE"
            exit 0
        fi
    fi
fi

# 2. Cache (last successful terminal query)
if [[ -f "$CACHE" ]]; then
    cat "$CACHE"
    exit 0
fi

# 3. System detection (fallback when no terminal context)
if [[ "$(uname)" == "Darwin" ]]; then
    defaults read -globalDomain AppleInterfaceStyle &>/dev/null && echo "dark" || echo "light"
    exit 0
elif [[ -f ~/.config/kdeglobals ]] && grep -q '^LookAndFeelPackage=.*[dD]ark' ~/.config/kdeglobals 2>/dev/null; then
    echo "dark"
    exit 0
elif command -v gsettings &>/dev/null; then
    [[ "$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)" == *"dark"* ]] && echo "dark" || echo "light"
    exit 0
fi

echo "dark"
