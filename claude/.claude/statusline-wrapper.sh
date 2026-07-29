#!/bin/bash

# Read JSON input once
input=$(cat)

# Get git info from existing script.
# Line 1: block template (@TRUNC@ = truncatable value slot).
# Line 2: raw truncatable value (branch or path).
# Line 3 (optional): diff stats to right-align.
git_output=$(echo "$input" | bash ~/.claude/statusline-command.sh)
line_tpl=$(printf '%s' "$git_output" | sed -n 1p)
trunc_val=$(printf '%s' "$git_output" | sed -n 2p)
diff_info=$(printf '%s' "$git_output" | sed -n 3p)

# Get context window info
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
context_limit=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

# Auto-compaction threshold: env override or default 95%
compact_pct="${CLAUDE_AUTOCOMPACT_PCT_OVERRIDE:-95}"

# Format token count with k suffix (rounded to nearest k)
format_k() {
    local num=$1
    if [ "$num" -ge 1000 ]; then
        local k=$(( (num + 500) / 1000 ))
        echo "${k}k"
    else
        echo "$num"
    fi
}

# --- Line 2 helpers (style from pchalasani/claude-code-tools statusline) ---
RESET=$'\033[0m'
BLINK=$'\033[5m'
DIM=$'\033[38;5;244m'
LABEL=$'\033[38;5;250m'
FG_WHITE=$'\033[97m'

# Format a unix-epoch reset time as a compact countdown, e.g. "2h13m", "4d6h"
fmt_reset() {
    local target=$1 now delta d h m
    now=$(date +%s)
    delta=$((target - now))
    [ "$delta" -le 0 ] && { echo "now"; return; }
    d=$((delta / 86400))
    h=$(((delta % 86400) / 3600))
    m=$(((delta % 3600) / 60))
    if [ "$d" -gt 0 ]; then echo "${d}d${h}h"
    elif [ "$h" -gt 0 ]; then echo "${h}h${m}m"
    else echo "${m}m"; fi
}

# Progress bar with its label inside: the text is the bar, and the color-coded
# fill advances across it. Usage: build_text_bar "5h (42%)" 42
build_text_bar() {
    local text=" $1 " pct=$2 len filled fill_bg fill_fg blink=""
    len=${#text}
    filled=$((pct * len / 100))
    [ "$filled" -gt "$len" ] && filled=$len
    [ "$filled" -lt 0 ] && filled=0
    if [ "$pct" -gt 89 ]; then fill_bg=$'\033[48;5;196m'; fill_fg=$'\033[97m'; blink=$BLINK
    elif [ "$pct" -gt 79 ]; then fill_bg=$'\033[48;5;208m'; fill_fg=$'\033[30m'
    elif [ "$pct" -gt 64 ]; then fill_bg=$'\033[48;5;220m'; fill_fg=$'\033[30m'
    else fill_bg=$'\033[48;5;29m'; fill_fg=$'\033[97m'; fi
    local empty_bg=$'\033[48;5;238m' empty_fg=$'\033[38;5;250m'
    printf '%s' "${blink}${fill_bg}${fill_fg}${text:0:filled}${RESET}${empty_bg}${empty_fg}${text:filled}${RESET}"
}

# Color based on usage proximity to compaction threshold
# Green < 50%, Yellow 50-75%, Red 75-100% of compaction threshold
usage_color() {
    local used=$1 threshold=$2
    local ratio=$((used * 100 / threshold))
    if [ "$ratio" -ge 75 ]; then
        echo '\033[0;31m'  # red
    elif [ "$ratio" -ge 50 ]; then
        echo '\033[0;33m'  # yellow
    else
        echo '\033[0;32m'  # green
    fi
}

# Compose line 1 from the block template + context info
compose_left() {
    local info=$1
    if [ "$context_limit" -gt 0 ]; then
        printf '%s '"$color"'%s/%s'"$reset" "$info" "$used_fmt" "$compact_fmt"
    else
        printf '%s' "$info"
    fi
}

strip_ansi() { sed $'s/\033\[[0-9;]*m//g'; }

if [ "$context_limit" -gt 0 ]; then
    tokens_used=$((context_limit * used_pct / 100))
    compact_at=$((context_limit * compact_pct / 100))
    used_fmt=$(format_k "$tokens_used")
    compact_fmt=$(format_k "$compact_at")
    color=$(usage_color "$tokens_used" "$compact_at")
    reset='\033[0m'
fi

# 5h session limit bar, slotted in after the model block (Pro/Max only)
five_seg=""
five_pct_raw=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$five_pct_raw" ]; then
    five_pct=$(printf '%.0f' "$five_pct_raw" 2>/dev/null)
    five_seg=$(build_text_bar "5h (${five_pct}%)" "$five_pct")
fi
line_tpl=${line_tpl//@5H@/$five_seg}

# Claude Code sets COLUMNS to the terminal width and renders the statusline
# with ~2-col margins on each side, so keep content within COLUMNS - 4.
width="${COLUMNS:-0}"
[ "$width" -gt 0 ] 2>/dev/null || width=$(tput cols 2>/dev/null || echo 0)
avail=$((width - 4))

left=$(compose_left "${line_tpl//@TRUNC@/$trunc_val}")
plain_left=$(printf '%s' "$left" | strip_ansi)
plain_diff=$(printf '%s' "$diff_info" | strip_ansi)

# Truncate the branch/path only when the line overflows the terminal.
# Branches lose their tail (feature/very-long…); paths lose their head (…ub/dotfiles).
if [ "$avail" -gt 0 ] && [ -n "$trunc_val" ]; then
    total=${#plain_left}
    [ -n "$diff_info" ] && total=$((total + 2 + ${#plain_diff}))
    over=$((total - avail))
    if [ "$over" -gt 0 ]; then
        keep=$(( ${#trunc_val} - over - 1 ))
        [ "$keep" -lt 6 ] && keep=6
        if [ "$keep" -lt ${#trunc_val} ]; then
            case $trunc_val in
                /*) short="…${trunc_val:$(( ${#trunc_val} - keep ))}";;
                *)  short="${trunc_val:0:$keep}…";;
            esac
            left=$(compose_left "${line_tpl//@TRUNC@/$short}")
            plain_left=$(printf '%s' "$left" | strip_ansi)
        fi
    fi
fi

# Right-align diff stats at the end of the line
if [ -n "$diff_info" ]; then
    pad=$((avail - ${#plain_left} - ${#plain_diff}))
    [ "$pad" -lt 2 ] && pad=2
    printf '%s%*s%s' "$left" "$pad" '' "$diff_info"
else
    printf '%s' "$left"
fi