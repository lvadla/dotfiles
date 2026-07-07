#!/bin/sh
# Detect terminal theme (dark/light)
# Priority: terminal query (OSC 11) → cache → system detection
# Output: "dark" or "light"

CACHE="/tmp/term-theme-$(id -u)"

BEL=$(printf '\007')
ESC=$(printf '\033')

# 1. Try terminal query via OSC 11 (uses /dev/tty directly so it works even when stdin is a pipe)
if [ -c /dev/tty ]; then
    # BSD stty (macOS) uses -f for the device; GNU stty uses -F
    case "$(uname)" in Darwin) TTYFLAG="-f" ;; *) TTYFLAG="-F" ;; esac
    old_settings=$(stty "$TTYFLAG" /dev/tty -g 2>/dev/null)
    if [ -n "$old_settings" ]; then
        # min 0 time 2: each read(2) returns what has arrived, or nothing
        # after 0.2s. dd does plain read(2) calls that honor VMIN/VTIME
        # (shell `read` builtins don't), so no read can hang — even when
        # the reply is eaten by lazygit's input loop.
        stty "$TTYFLAG" /dev/tty raw -echo min 0 time 2 2>/dev/null
        printf '\033]11;?\007' >/dev/tty
        response=""
        i=0
        while [ $i -lt 3 ]; do
            chunk=$(dd if=/dev/tty bs=64 count=1 2>/dev/null)
            [ -z "$chunk" ] && break
            response="$response$chunk"
            case $response in
                *"$BEL"* | *"$ESC"\\*) break ;;
            esac
            i=$((i + 1))
        done
        stty "$TTYFLAG" /dev/tty "$old_settings" 2>/dev/null

        rgb=$(printf '%s' "$response" | sed -n 's/.*rgb:\([0-9a-fA-F]*\)\/\([0-9a-fA-F]*\)\/\([0-9a-fA-F]*\).*/\1 \2 \3/p')
        if [ -n "$rgb" ]; then
            set -- $rgb
            r=$((0x$(printf '%.2s' "$1")))
            g=$((0x$(printf '%.2s' "$2")))
            b=$((0x$(printf '%.2s' "$3")))
            luminance=$(((2126 * r + 7152 * g + 722 * b) / 10000))
            if [ "$luminance" -lt 128 ]; then result="dark"; else result="light"; fi
            echo "$result" | tee "$CACHE"
            exit 0
        fi
    fi
fi

# 2. Cache (last successful terminal query)
if [ -f "$CACHE" ]; then
    cat "$CACHE"
    exit 0
fi

# 3. System detection (fallback when no terminal context)
if [ "$(uname)" = "Darwin" ]; then
    if defaults read -globalDomain AppleInterfaceStyle >/dev/null 2>&1; then echo "dark"; else echo "light"; fi
    exit 0
elif [ -f ~/.config/kdeglobals ] && grep -q '^LookAndFeelPackage=.*[dD]ark' ~/.config/kdeglobals 2>/dev/null; then
    echo "dark"
    exit 0
elif command -v gsettings >/dev/null 2>&1; then
    case "$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)" in
        *dark*) echo "dark" ;;
        *) echo "light" ;;
    esac
    exit 0
fi

echo "dark"
