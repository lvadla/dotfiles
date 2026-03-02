#!/bin/bash

# Read JSON input once
input=$(cat)

# Get git info from existing script
git_info=$(echo "$input" | bash ~/.claude/statusline-command.sh)

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

# Only show context info if we have valid data
if [ "$context_limit" -gt 0 ]; then
    tokens_used=$((context_limit * used_pct / 100))
    compact_at=$((context_limit * compact_pct / 100))
    used_fmt=$(format_k "$tokens_used")
    compact_fmt=$(format_k "$compact_at")
    color=$(usage_color "$tokens_used" "$compact_at")
    reset='\033[0m'
    printf '%s | '"$color"'%s/%s'"$reset" "$git_info" "$used_fmt" "$compact_fmt"
else
    printf '%s' "$git_info"
fi
