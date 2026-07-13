#!/usr/bin/env bash

set -euo pipefail

: "${HOME:?HOME must be set}"

script_dir="$(
  CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1
  pwd
)"

codex_source="${script_dir}/AGENTS.md"
codex_destination="${HOME}/.codex/AGENTS.md"
claude_source="${script_dir}/CLAUDE.md"
claude_destination="${HOME}/.claude/CLAUDE.md"

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
