#!/bin/bash
# Detect terminal theme (dark/light)
# Priority: terminal query (OSC 11) → TERM_THEME env var → system detection
# Output: "dark" or "light"

# 1. Try terminal query via OSC 11 (only works with TTY)
if [[ -t 0 ]]; then
    old_settings=$(stty -g 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        stty raw -echo min 0 time 5 2>/dev/null
        response=$(printf '\e]11;?\a' >/dev/tty; dd bs=50 count=1 2>/dev/null </dev/tty)
        stty "$old_settings" 2>/dev/null

        if [[ "$response" =~ rgb:([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+) ]]; then
            r=$((16#${BASH_REMATCH[1]:0:2}))
            g=$((16#${BASH_REMATCH[2]:0:2}))
            b=$((16#${BASH_REMATCH[3]:0:2}))
            luminance=$(( (2126 * r + 7152 * g + 722 * b) / 10000 ))
            [[ $luminance -lt 128 ]] && echo "dark" || echo "light"
            exit 0
        fi
    fi
fi

# 2. Env var from parent shell (set by precmd with TTY access, reflects terminal not system)
if [[ -n "$TERM_THEME" ]]; then
    echo "$TERM_THEME"
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
