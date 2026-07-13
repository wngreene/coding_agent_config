#!/usr/bin/env bash

set -euo pipefail

script_dir="$(
  CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1
  pwd
)"

usage() {
  printf '%s\n' \
    'Usage: bash install.sh [options]' \
    '' \
    'Options:' \
    '  --claude-config-dir PATH  Install CLAUDE.md under PATH.' \
    '  --codex-home PATH          Install AGENTS.md under PATH.' \
    '  -h, --help                 Show this help.' \
    '' \
    'Defaults honor CLAUDE_CONFIG_DIR and CODEX_HOME, then fall back to the' \
    'standard user config directories. Command-line options take precedence.'
}

require_option_value() {
  local option="$1"
  local value_count="$2"
  local value="${3:-}"

  if [[ "${value_count}" -lt 2 || -z "${value}" ]]; then
    printf 'Option %s requires a non-empty path.\n' "${option}" >&2
    return 1
  fi
}

claude_config_dir="${CLAUDE_CONFIG_DIR:-}"
codex_home="${CODEX_HOME:-}"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --claude-config-dir)
      require_option_value "$1" "$#" "${2:-}"
      claude_config_dir="$2"
      shift 2
      ;;
    --codex-home)
      require_option_value "$1" "$#" "${2:-}"
      codex_home="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${claude_config_dir}" || -z "${codex_home}" ]]; then
  : "${HOME:?HOME must be set when a config directory is not specified}"
  claude_config_dir="${claude_config_dir:-${HOME}/.claude}"
  codex_home="${codex_home:-${HOME}/.codex}"
fi

codex_source="${script_dir}/AGENTS.md"
codex_destination="${codex_home}/AGENTS.md"
claude_source="${script_dir}/CLAUDE.md"
claude_destination="${claude_config_dir}/CLAUDE.md"

is_expected_link() {
  local source="$1"
  local destination="$2"

  [[ -L "${destination}" && "${destination}" -ef "${source}" ]]
}

preflight_link() {
  local source="$1"
  local destination="$2"

  if [[ -e "${destination}" || -L "${destination}" ]]; then
    if is_expected_link "${source}" "${destination}"; then
      return
    fi

    printf 'Refusing to replace existing path: %s\n' "${destination}" >&2
    return 1
  fi
}

install_link() {
  local source="$1"
  local destination="$2"

  if is_expected_link "${source}" "${destination}"; then
    printf 'Already linked: %s\n' "${destination}"
    return
  fi

  mkdir -p "$(dirname -- "${destination}")"
  ln -s "${source}" "${destination}"
  printf 'Linked %s -> %s\n' "${destination}" "${source}"
}

preflight_link "${codex_source}" "${codex_destination}"
preflight_link "${claude_source}" "${claude_destination}"

install_link "${codex_source}" "${codex_destination}"
install_link "${claude_source}" "${claude_destination}"
