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
