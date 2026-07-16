#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'Usage: %s <codex|claude> <event> [JSON payload]\n' "$0" >&2
  exit 2
}

[[ "$#" -ge 2 ]] || usage

# Invoked by clicking a notification: bring the originating iTerm2 session's
# window, tab, and pane to the front.
if [[ "$1" == "focus-session" ]]; then
  exec /usr/bin/osascript - "$2" <<'APPLESCRIPT'
on run argv
  set targetId to item 1 of argv
  tell application "iTerm2"
    activate
    repeat with w in windows
      repeat with t in tabs of w
        repeat with s in sessions of t
          if unique ID of s is targetId then
            select w
            select t
            select s
            return
          end if
        end repeat
      end repeat
    end repeat
  end tell
end run
APPLESCRIPT
fi

notifier_command="${BASH_SOURCE[0]}"
if [[ "${notifier_command}" != /* ]]; then
  notifier_command="${PWD}/${notifier_command}"
fi

agent="$1"
event="$2"
shift 2

case "${agent}" in
  codex) agent_title="Codex" ;;
  claude) agent_title="Claude" ;;
  *) usage ;;
esac

if [[ "$#" -gt 0 ]]; then
  payload="$1"
else
  payload="$(cat)"
fi

if ! jq -e . >/dev/null 2>&1 <<<"${payload}"; then
  payload='{}'
fi

json_value() {
  jq -r "$1 // empty" <<<"${payload}"
}

session_id="$(json_value '."thread-id" // .session_id')"
cwd="$(json_value '.cwd')"
cwd="${cwd:-${PWD}}"
project="$(basename -- "${cwd}")"

if [[ -z "${session_id}" ]]; then
  session_id="${ITERM_SESSION_ID:-${cwd}}"
fi

state_root="${CODING_AGENT_NOTIFY_STATE_DIR:-${TMPDIR:-/tmp}/coding-agent-notifications}"
state_key="$(printf '%s' "${agent}:${session_id}" | shasum -a 256 | awk '{print $1}')"
state_file="${state_root}/${state_key}.state"
completion_threshold="${CODING_AGENT_NOTIFY_MIN_SECONDS:-30}"
test_log="${CODING_AGENT_NOTIFY_TEST_LOG:-}"

mkdir -p "${state_root}"

state_value() {
  local key="$1"

  [[ -f "${state_file}" ]] || return 0
  awk -F= -v key="${key}" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "${state_file}"
}

write_state() {
  local started_at="$1"
  local status="$2"
  local temporary="${state_file}.$$"

  printf 'started_at=%s\nstatus=%s\n' "${started_at}" "${status}" >"${temporary}"
  mv "${temporary}" "${state_file}"
}

current_branch() {
  git -C "${cwd}" rev-parse --abbrev-ref HEAD 2>/dev/null || printf '%s\n' "${project}"
}

# Hook processes spawned by Claude Code and Codex have no controlling
# terminal, so /dev/tty is unusable. Fall back to walking up the process tree
# to the agent process and using its tty device.
resolve_tty() {
  local pid tty_name

  if { : >/dev/tty; } 2>/dev/null; then
    tty </dev/tty 2>/dev/null && return 0
  fi

  pid=$$
  while [[ -n "${pid}" && "${pid}" != 0 && "${pid}" != 1 ]]; do
    tty_name="$(ps -o tty= -p "${pid}" 2>/dev/null | tr -d '[:space:]')"
    if [[ -n "${tty_name}" && "${tty_name}" != '??' ]]; then
      printf '/dev/%s\n' "${tty_name}"
      return 0
    fi
    pid="$(ps -o ppid= -p "${pid}" 2>/dev/null | tr -d '[:space:]')"
  done
  return 1
}

output_tty="$(resolve_tty)" || output_tty=""

log_test_action() {
  [[ -n "${test_log}" ]] || return 1
  printf '%s\n' "$1" >>"${test_log}"
}

set_tab_state() {
  local state="$1"
  local branch title red green blue

  if log_test_action "tab|${agent}|${state}|${project}"; then
    return
  fi

  [[ -n "${output_tty}" && -w "${output_tty}" ]] || return

  branch="$(current_branch)"
  case "${state}" in
    working)
      red=30 green=130 blue=255
      title="${agent}: ${branch}"
      ;;
    attention)
      red=255 green=140 blue=0
      title="input ${agent}: ${branch}"
      ;;
    done)
      red=0 green=230 blue=70
      title="done ${agent}: ${branch}"
      ;;
    failed)
      red=255 green=30 blue=30
      title="failed ${agent}: ${branch}"
      ;;
    idle)
      printf '\033]6;1;bg;red;default\007\033]6;1;bg;green;default\007\033]6;1;bg;blue;default\007' >"${output_tty}"
      title="${branch}"
      ;;
    *) return ;;
  esac

  if [[ "${state}" != "idle" ]]; then
    printf '\033]6;1;bg;red;brightness;%s\007\033]6;1;bg;green;brightness;%s\007\033]6;1;bg;blue;brightness;%s\007' \
      "${red}" "${green}" "${blue}" >"${output_tty}"
  fi
  printf '\033]1;%s\007' "${title}" >"${output_tty}"
}

originating_tty() {
  printf '%s\n' "${output_tty}"
}

is_focused() {
  local active_id active_tty iterm_frontmost source_id source_tty

  case "${CODING_AGENT_NOTIFY_FOCUS:-auto}" in
    focused) return 0 ;;
    unfocused) return 1 ;;
  esac

  iterm_frontmost="$(osascript -e 'tell application "iTerm2" to get frontmost' 2>/dev/null || true)"
  [[ "${iterm_frontmost}" == "true" ]] || return 1

  source_tty="$(originating_tty)"
  active_tty="$(osascript -e 'tell application "iTerm2" to if (count of windows) > 0 then get tty of current session of current window' 2>/dev/null || true)"
  if [[ -n "${source_tty}" && -n "${active_tty}" ]]; then
    [[ "${source_tty}" == "${active_tty}" ]]
    return
  fi

  source_id="${ITERM_SESSION_ID:-}"
  active_id="$(osascript -e 'tell application "iTerm2" to if (count of windows) > 0 then get unique id of current session of current window' 2>/dev/null || true)"
  if [[ -n "${source_id}" && -n "${active_id}" ]]; then
    [[ "${source_id}" == *"${active_id}"* ]]
    return
  fi

  # If the exact session cannot be identified, avoid interrupting while iTerm2
  # is already frontmost.
  return 0
}

start_codex_exit_watcher() {
  local branch owner_pid source_tty

  [[ "${agent}" == "codex" && -z "${test_log}" ]] || return
  source_tty="$(originating_tty)"
  [[ -n "${source_tty}" ]] || return

  branch="$(current_branch)"
  owner_pid="${PPID}"
  # shellcheck disable=SC2016 # The nested shell expands its positional arguments.
  nohup bash -c '
    owner_pid="$1"
    source_tty="$2"
    branch="$3"
    state_file="$4"
    while kill -0 "${owner_pid}" 2>/dev/null; do sleep 1; done
    printf "\033]6;1;bg;red;default\007\033]6;1;bg;green;default\007\033]6;1;bg;blue;default\007" >"${source_tty}"
    printf "\033]1;%s\007" "${branch}" >"${source_tty}"
    rm -f "${state_file}"
  ' coding-agent-exit-watcher "${owner_pid}" "${source_tty}" "${branch}" "${state_file}" \
    </dev/null >/dev/null 2>&1 &
}

format_duration() {
  local seconds="$1"

  if (( seconds < 60 )); then
    printf '%ss' "${seconds}"
  else
    printf '%sm %ss' "$((seconds / 60))" "$((seconds % 60))"
  fi
}

send_notification() {
  local kind="$1"
  local title message sound
  local -a notification_command

  case "${kind}" in
    attention)
      title="🟠 ${agent_title} needs attention"
      message="${project} is waiting for input"
      sound="Purr"
      ;;
    done)
      title="🟢 ${agent_title} finished"
      message="${project} finished in $(format_duration "$2")"
      sound="Glass"
      ;;
    failed)
      title="🔴 ${agent_title} failed"
      message="${project} stopped because of an error"
      sound="Basso"
      ;;
    *) return ;;
  esac

  if log_test_action "notification|${agent}|${kind}|${project}|${sound}"; then
    return
  fi

  if command -v terminal-notifier >/dev/null 2>&1; then
    notification_command=(terminal-notifier -title "${title}" -message "${message}" -group "coding-agent-${state_key}")
    if [[ -n "${ITERM_SESSION_ID:-}" ]]; then
      notification_command+=(-execute "'${notifier_command}' focus-session '${ITERM_SESSION_ID##*:}'")
    else
      notification_command+=(-activate com.googlecode.iterm2)
    fi
    if [[ -n "${sound}" ]]; then
      notification_command+=(-sound "${sound}")
    fi
    "${notification_command[@]}" >/dev/null 2>&1 &
    return
  fi

  osascript - "${title}" "${message}" <<'APPLESCRIPT' >/dev/null 2>&1 &
on run argv
  display notification (item 2 of argv) with title (item 1 of argv)
end run
APPLESCRIPT

  if [[ -n "${sound}" && -f "/System/Library/Sounds/${sound}.aiff" ]]; then
    afplay "/System/Library/Sounds/${sound}.aiff" >/dev/null 2>&1 &
  fi
}

now="$(date +%s)"
started_at="$(state_value started_at)"
started_at="${started_at:-0}"
status="$(state_value status)"

case "${event}" in
  session-start)
    write_state 0 idle
    set_tab_state working
    start_codex_exit_watcher
    ;;
  prompt-submitted)
    write_state "${now}" working
    set_tab_state working
    ;;
  working)
    if [[ "${status}" == "attention" ]]; then
      write_state "${started_at}" working
      set_tab_state working
    fi
    ;;
  attention)
    write_state "${started_at}" attention
    set_tab_state attention
    if ! is_focused; then
      send_notification attention
    fi
    ;;
  turn-complete)
    duration=0
    if [[ "${started_at}" =~ ^[0-9]+$ ]] && (( started_at > 0 && now >= started_at )); then
      duration=$((now - started_at))
    fi
    write_state "${started_at}" "done"
    set_tab_state "done"
    if [[ "${completion_threshold}" =~ ^[0-9]+$ ]] && (( duration >= completion_threshold )) && ! is_focused; then
      send_notification "done" "${duration}"
    fi
    ;;
  failure)
    write_state "${started_at}" failed
    set_tab_state failed
    if ! is_focused; then
      send_notification failed
    fi
    ;;
  session-end)
    set_tab_state idle
    rm -f "${state_file}"
    ;;
  *) usage ;;
esac
