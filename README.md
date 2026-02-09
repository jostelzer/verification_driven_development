# Verification-Driven Development Skill

A Codex skill that enforces executable verification before completion.

## Contents

- `verification-driven-development/`: skill folder (`SKILL.md`, `agents/`, `references/`)
- `install.sh`: install or update the skill
- `uninstall.sh`: remove the skill from local skill directories

## Install

```bash
cd ~/git/verification_driven_development
./install.sh
```

Defaults:
- `--mode symlink` for easy local iteration (edits in this repo are reflected immediately)
- `--target auto` for compatibility:
1. Use `~/.agents/skills` if it exists
2. Else use `~/.codex/skills` (or `$CODEX_HOME/skills`) if it exists
3. Else create and use `~/.agents/skills`

## Common install variants

Install as copied files (release-style):

```bash
./install.sh --mode copy
```

Install to both locations:

```bash
./install.sh --target both
```

Preview actions only:

```bash
./install.sh --dry-run
```

## Update after edits

If installed with symlink mode (default), no reinstall is needed.
If installed with copy mode, re-run:

```bash
./install.sh --mode copy
```

## Uninstall

```bash
./uninstall.sh
```

`uninstall.sh` defaults to `--target auto` and removes from both standard locations.

## Optional validation

If you have `skill-creator` tooling installed:

```bash
python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py \
  ~/git/verification_driven_development/verification-driven-development
```
