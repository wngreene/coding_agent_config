#!/usr/bin/env bash

set -euo pipefail

script_dir="$(
  CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1
  pwd
)"
installer="${script_dir}/install.sh"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/coding_agent_config_test.XXXXXX")"

cleanup() {
  rm -rf "${test_root}"
}

assert_link() {
  local expected_source="$1"
  local actual_link="$2"

  if [[ ! -L "${actual_link}" || ! "${actual_link}" -ef "${expected_source}" ]]; then
    printf 'Expected %s to link to %s\n' "${actual_link}" "${expected_source}" >&2
    return 1
  fi
}

assert_config_links() {
  local claude_dir="$1"
  local codex_dir="$2"

  assert_link "${script_dir}/AGENTS.md" "${codex_dir}/AGENTS.md"
  assert_link "${script_dir}/codex/config.toml" "${codex_dir}/config.toml"
  assert_link "${script_dir}/CLAUDE.md" "${claude_dir}/CLAUDE.md"
  assert_link "${script_dir}/claude/settings.json" "${claude_dir}/settings.json"
  assert_link "${script_dir}/claude/iterm2-tab.sh" "${claude_dir}/iterm2-tab.sh"
  assert_link "${script_dir}/claude/statusline.sh" "${claude_dir}/statusline.sh"
}

test_default_directories() {
  local home="${test_root}/default_home"

  HOME="${home}" CLAUDE_CONFIG_DIR='' CODEX_HOME='' bash "${installer}"

  assert_config_links "${home}/.claude" "${home}/.codex"
}

test_environment_directories() {
  local home="${test_root}/environment_home"
  local claude_dir="${test_root}/environment/claude"
  local codex_dir="${test_root}/environment/codex"

  HOME="${home}" CLAUDE_CONFIG_DIR="${claude_dir}" CODEX_HOME="${codex_dir}" \
    bash "${installer}"

  assert_config_links "${claude_dir}" "${codex_dir}"
}

test_command_line_directories() {
  local home="${test_root}/command_line_home"
  local claude_dir="${test_root}/command_line/claude"
  local codex_dir="${test_root}/command_line/codex"

  HOME="${home}" bash "${installer}" \
    --claude-config-dir "${claude_dir}" \
    --codex-home "${codex_dir}"

  assert_config_links "${claude_dir}" "${codex_dir}"
}

test_command_line_overrides_environment() {
  local home="${test_root}/override_home"
  local environment_claude_dir="${test_root}/override/environment_claude"
  local environment_codex_dir="${test_root}/override/environment_codex"
  local argument_claude_dir="${test_root}/override/argument_claude"
  local argument_codex_dir="${test_root}/override/argument_codex"

  HOME="${home}" \
    CLAUDE_CONFIG_DIR="${environment_claude_dir}" \
    CODEX_HOME="${environment_codex_dir}" \
    bash "${installer}" \
    --claude-config-dir "${argument_claude_dir}" \
    --codex-home "${argument_codex_dir}"

  assert_config_links "${argument_claude_dir}" "${argument_codex_dir}"

  [[ ! -e "${environment_codex_dir}/AGENTS.md" ]]
  [[ ! -e "${environment_claude_dir}/CLAUDE.md" ]]
}

trap cleanup EXIT

test_default_directories
test_environment_directories
test_command_line_directories
test_command_line_overrides_environment

printf 'All installer tests passed.\n'
