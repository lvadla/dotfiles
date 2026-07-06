#!/bin/bash

# Read JSON input
input=$(cat)

# Extract values from JSON (without jq)
cwd=$(echo "$input" | sed -n 's/.*"current_dir":"\([^"]*\)".*/\1/p')

# Git information (skip optional locks for performance)
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
	# Get just the repo name (the git root directory basename)
    git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
    repo_name=$(basename "$git_root")

    # Get branch
    branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

    # Get staged/unstaged/untracked counts in one call
    status_output=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
    staged=$(echo "$status_output" | grep -c '^[MADRC]')
    unstaged=$(echo "$status_output" | grep -c '^.[MDRC]')
    untracked=$(echo "$status_output" | grep -c '^??')

    # Get line changes vs main (prefer origin/main, fall back to local main, then origin/master, then master)
    main_branch=""
    for candidate in origin/main main origin/master master; do
        if git -C "$cwd" rev-parse --verify "$candidate" >/dev/null 2>&1; then
            main_branch="$candidate"
            break
        fi
    done

    # Only show diff stats if we found a baseline and we're not on it
    base_branch_short="${main_branch#origin/}"
    if [ -n "$main_branch" ] && [ "$branch" != "$base_branch_short" ]; then
	    # Use numstat to calculate added, modified, and deleted lines
	    added=0
	    modified=0
	    deleted=0

	    while IFS=$'\t' read -r add del file; do
	        if [ -n "$add" ] && [ -n "$del" ] && [ "$add" != "-" ] && [ "$del" != "-" ]; then
	            if [ "$add" -gt "$del" ]; then
	                modified=$((modified + del))
	                added=$((added + add - del))
	            elif [ "$del" -gt "$add" ]; then
	                modified=$((modified + add))
	                deleted=$((deleted + del - add))
	            else
	                modified=$((modified + add))
	            fi
	        fi
	    done <<< "$(git -C "$cwd" --no-optional-locks diff --numstat "$main_branch"...HEAD 2>/dev/null)"

	    printf '\033[01;36m%s\033[0m | \033[01;34m%s\033[0m \033[0;32m+%s\033[0m/\033[38;5;208m~%s\033[0m/\033[0;31m-%s\033[0m' \
	    "$repo_name" "$branch" "$added" "$modified" "$deleted"
    else
	    printf '\033[01;36m%s\033[0m | \033[01;34m%s\033[0m' \
	    "$repo_name" "$branch"
    fi
else
	# Not a git repo
	printf '\033[01;36m%s\033[00m' "$cwd"
fi
