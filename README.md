# Coding Agent Config

Personal communication guidance shared by Codex and Claude Code without adding
user-specific preferences to a project repository.

`AGENTS.md` is the canonical guidance. `CLAUDE.md` is a repository-relative
symlink to it so both agents read the same instructions.

## Install

Run:

```bash
bash install.sh
```

The installer creates these user-level links:

```text
~/.codex/AGENTS.md   -> <repository>/AGENTS.md
~/.claude/CLAUDE.md -> <repository>/CLAUDE.md
```

It is safe to run again when the expected links already exist. It refuses to
replace conflicting files or links; move those paths elsewhere before retrying.

Because the installed links are absolute, rerun the installer after moving the
repository.

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
