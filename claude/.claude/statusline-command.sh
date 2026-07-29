#!/bin/bash

# Read JSON input
input=$(cat)

# Extract values from JSON (without jq)
cwd=$(echo "$input" | sed -n 's/.*"current_dir":"\([^"]*\)".*/\1/p')

# Extract model name, clean up: drop claude- prefix and date suffix, truncate
model=$(echo "$input" | jq -r '
  if .model | type == "object" then .model.id // .model.name // "claude"
  elif .model | type == "string" then .model
  else "claude"
  end
' 2>/dev/null)
[ -z "$model" ] || [ "$model" = "null" ] && model="claude"
model=$(echo "$model" | sed 's/claude-//' | sed 's/-[0-9]\{8\}$//' | cut -c1-10)

# Model block: Claude orange
model_bg='\033[48;2;217;119;87m'

# Branch block background: light blue when git tree is clean, gold when dirty
git_bg='\033[48;5;75m'

# Git information (skip optional locks for performance)
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
	# Get just the repo name (the git root directory basename)
    git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
    repo_name=$(basename "$git_root")

    # Get branch (the wrapper truncates it only if the line overflows)
    branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

    # Get staged/unstaged/untracked counts in one call
    status_output=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
    [ -n "$status_output" ] && git_bg='\033[48;2;239;199;116m'
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
	    # Diff from the merge-base to the working tree so staged and
	    # unstaged changes count, not just commits
	    merge_base=$(git -C "$cwd" --no-optional-locks merge-base "$main_branch" HEAD 2>/dev/null)

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
	    done <<< "$(git -C "$cwd" --no-optional-locks diff --numstat "${merge_base:-$main_branch}" 2>/dev/null)"

	    # Colored blocks: model on orange, repo on blue, branch on blue (clean) / gold (dirty)
	    # Output protocol for the wrapper:
	    #   line 1: block template, @TRUNC@ marks the truncatable value
	    #   line 2: the raw truncatable value (branch or path)
	    #   line 3 (optional): diff stats to right-align at line end
	    printf "$model_bg"'\033[1;30m %s \033[0m@5H@\033[44m\033[30m %s \033[0m'"$git_bg"'\033[30m @TRUNC@ \033[0m\n%s\n\033[0;32m+%s\033[0m/\033[38;5;208m~%s\033[0m/\033[0;31m-%s\033[0m' \
	    "$model" "$repo_name" "$branch" "$added" "$modified" "$deleted"
    else
	    printf "$model_bg"'\033[1;30m %s \033[0m@5H@\033[44m\033[30m %s \033[0m'"$git_bg"'\033[30m @TRUNC@ \033[0m\n%s' \
	    "$model" "$repo_name" "$branch"
    fi
else
	# Not a git repo: model block, then cwd on blue block
	printf "$model_bg"'\033[1;30m %s \033[0m@5H@\033[44m\033[30m @TRUNC@ \033[0m\n%s' "$model" "$cwd"
fi
