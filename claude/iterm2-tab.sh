#!/bin/bash
# Helper script for iTerm2 tab title and color management in Claude Code hooks.
# Usage: iterm2-tab.sh <start|stop|notification|reset|end>

set -o pipefail

# Exit cleanly if no controlling terminal is attached
if ! { : > /dev/tty; } 2>/dev/null; then exit 0; fi

get_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || basename "$PWD"
}

set_tab_title() {
  printf '\033]1;%s\007' "$1" > /dev/tty
}

set_tab_color() {
  printf '\033]6;1;bg;red;brightness;%s\007\033]6;1;bg;green;brightness;%s\007\033]6;1;bg;blue;brightness;%s\007' "$1" "$2" "$3" > /dev/tty
}

reset_tab_color() {
  printf '\033]6;1;bg;red;default\007\033]6;1;bg;green;default\007\033]6;1;bg;blue;default\007' > /dev/tty
}

branch=$(get_branch)

case "${1:-}" in
  start)
    reset_tab_color
    set_tab_title "<b>claude:</b> $branch"
    ;;
  stop)
    set_tab_color 10 45 10
    set_tab_title "<font color=\"lime\">done</font> <b>claude:</b> $branch"
    ;;
  notification)
    set_tab_color 70 38 0
    set_tab_title "<font color=\"orange\">input</font> <b>claude:</b> $branch"
    ;;
  reset)
    reset_tab_color
    set_tab_title "<b>claude:</b> $branch"
    ;;
  end)
    reset_tab_color
    set_tab_title "$branch"
    ;;
  *)
    echo "Usage: $0 <start|stop|notification|reset|end>" >&2
    exit 1
    ;;
esac
