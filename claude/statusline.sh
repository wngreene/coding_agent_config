#!/bin/bash
# Claude Code status line script.
# Receives JSON on stdin with session metadata.
# Displays: <branch> | <model> | <context bar> <pct>% | $<cost>

set -euo pipefail

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || basename "$PWD")

json=$(cat)

model=$(echo "$json" | jq -r '.model.display_name // "?"')
pct=$(echo "$json" | jq -r '.context_window.used_percentage // 0')
cost=$(echo "$json" | jq -r '.cost.total_cost_usd // 0')

# Build progress bar (10 chars wide)
filled=$(( pct / 10 ))
empty=$(( 10 - filled ))
bar=""
for ((i = 0; i < filled; i++)); do bar+="█"; done
for ((i = 0; i < empty; i++)); do bar+="░"; done

# Format cost
cost_fmt=$(printf '$%.2f' "$cost")

echo "$branch  |  $model  |  $bar ${pct}%  |  $cost_fmt"
