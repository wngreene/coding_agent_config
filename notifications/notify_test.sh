#!/usr/bin/env bash

set -euo pipefail

script_dir="$(
  CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1
  pwd
)"
notifier="${script_dir}/notify.sh"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/coding_agent_notify_test.XXXXXX")"
log="${test_root}/actions.log"

cleanup() {
  rm -rf "${test_root}"
}

trap cleanup EXIT

run_event() {
  local agent="$1"
  local event="$2"
  local payload="$3"

  CODING_AGENT_NOTIFY_STATE_DIR="${test_root}/state" \
    CODING_AGENT_NOTIFY_TEST_LOG="${log}" \
    CODING_AGENT_NOTIFY_FOCUS=unfocused \
    CODING_AGENT_NOTIFY_MIN_SECONDS=0 \
    bash "${notifier}" "${agent}" "${event}" "${payload}"
}

run_event_with_policy() {
  local agent="$1"
  local event="$2"
  local payload="$3"
  local focus="$4"
  local threshold="$5"

  CODING_AGENT_NOTIFY_STATE_DIR="${test_root}/state" \
    CODING_AGENT_NOTIFY_TEST_LOG="${log}" \
    CODING_AGENT_NOTIFY_FOCUS="${focus}" \
    CODING_AGENT_NOTIFY_MIN_SECONDS="${threshold}" \
    bash "${notifier}" "${agent}" "${event}" "${payload}"
}

assert_logged() {
  local expected="$1"

  if ! grep -Fqx "${expected}" "${log}"; then
    printf 'Expected notification action was not logged: %s\n' "${expected}" >&2
    return 1
  fi
}

assert_not_logged() {
  local unexpected="$1"

  if grep -Fqx "${unexpected}" "${log}"; then
    printf 'Unexpected notification action was logged: %s\n' "${unexpected}" >&2
    return 1
  fi
}

claude_payload='{"session_id":"claude-session","cwd":"/tmp/example-project"}'
codex_payload='{"thread-id":"codex-session","cwd":"/tmp/example-project"}'

run_event claude prompt-submitted "${claude_payload}"
run_event claude attention "${claude_payload}"
run_event claude working "${claude_payload}"
run_event claude turn-complete "${claude_payload}"
run_event claude failure "${claude_payload}"
run_event claude session-end "${claude_payload}"
run_event codex prompt-submitted "${codex_payload}"
run_event codex turn-complete "${codex_payload}"

assert_logged 'tab|claude|working|example-project'
assert_logged 'tab|claude|attention|example-project'
assert_logged 'notification|claude|attention|example-project|Purr'
assert_logged 'tab|claude|done|example-project'
assert_logged 'notification|claude|done|example-project|Glass'
assert_logged 'tab|claude|failed|example-project'
assert_logged 'notification|claude|failed|example-project|Basso'
assert_logged 'tab|claude|idle|example-project'
assert_logged 'tab|codex|done|example-project'
assert_logged 'notification|codex|done|example-project|Glass'

quiet_payload='{"session_id":"quiet-session","cwd":"/tmp/quiet-project"}'
run_event_with_policy claude prompt-submitted "${quiet_payload}" unfocused 30
run_event_with_policy claude turn-complete "${quiet_payload}" unfocused 30
assert_not_logged 'notification|claude|done|quiet-project|Glass'

focused_payload='{"session_id":"focused-session","cwd":"/tmp/focused-project"}'
run_event_with_policy claude attention "${focused_payload}" focused 0
assert_logged 'tab|claude|attention|focused-project'
assert_not_logged 'notification|claude|attention|focused-project|Purr'

printf 'All notification tests passed.\n'
