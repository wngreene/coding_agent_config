# Coding Agent Config

Personal guidance and settings shared by Codex and Claude Code without adding
user-specific preferences to individual project repositories.

`AGENTS.md` is the canonical guidance. `CLAUDE.md` is a repository-relative
symlink to it so both agents read the same instructions. The repository also
tracks personal Claude Code and Codex settings.

## Install

Run:

```bash
bash install.sh
```

The installer creates these user-level links:

```text
~/.codex/AGENTS.md   -> <repository>/AGENTS.md
~/.codex/config.toml -> <repository>/codex/config.toml
~/.codex/notify.sh -> <repository>/notifications/notify.sh
~/.claude/CLAUDE.md -> <repository>/CLAUDE.md
~/.claude/settings.json -> <repository>/claude/settings.json
~/.claude/notify.sh -> <repository>/notifications/notify.sh
~/.claude/iterm2-tab.sh -> <repository>/claude/iterm2-tab.sh
~/.claude/statusline.sh -> <repository>/claude/statusline.sh
```

## Notifications

Codex and Claude Code share a balanced notification policy:

- Input needed: amber tab, desktop notification, and the Purr sound.
- Turn finished: green tab; a quiet desktop notification only for turns that
  take at least 30 seconds.
- Failure: red tab, desktop notification, and the Basso sound when the agent
  exposes a failure event.
- Focused sessions do not produce desktop notifications or sounds.

Set `CODING_AGENT_NOTIFY_MIN_SECONDS` when launching an agent to change the
long-turn threshold. Notification bodies identify the agent and project but do
not include prompt or response text.

It is safe to run again when the expected links already exist. It refuses to
replace conflicting files or links; move those paths elsewhere before retrying.

Because the installed links are absolute, rerun the installer after moving the
repository.

For the personal iCloud Claude profile used to seed this repository, run:

```bash
bash install.sh --claude-config-dir "$HOME/.claude_icloud"
```

## Multiple profiles

Claude Code uses `CLAUDE_CONFIG_DIR` for an alternate configuration root.
Codex uses the equivalent `CODEX_HOME` variable. The installer honors both:

```bash
CLAUDE_CONFIG_DIR="$HOME/.claude_work" \
CODEX_HOME="$HOME/.codex_work" \
bash install.sh
```

The same directories can be selected with command-line options:

```bash
bash install.sh \
  --claude-config-dir "$HOME/.claude_work" \
  --codex-home "$HOME/.codex_work"
```

Options take precedence over environment variables. Set the matching
environment variable when launching each agent so it uses that profile:

```bash
CLAUDE_CONFIG_DIR="$HOME/.claude_work" claude
CODEX_HOME="$HOME/.codex_work" codex
```

Run `bash install.sh --help` for the complete option summary.

## Test

```bash
bash install_test.sh
```
