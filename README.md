# Verification-Gated Coding Skill

A Codex skill that enforces executable verification before completion.

## Contents

- `verification-gated-coding/`: skill folder (`SKILL.md`, `agents/`, `references/`)
- `install.sh`: install or update the skill in `~/.codex/skills`
- `uninstall.sh`: remove the installed skill

## Install

```bash
cd ~/git/verification_gated_coding
./install.sh
```

## Update after edits

```bash
cd ~/git/verification_gated_coding
./install.sh
```

The installer backs up any existing installed version to:
`~/.codex/skills/verification-gated-coding.bak.<timestamp>`

## Uninstall

```bash
cd ~/git/verification_gated_coding
./uninstall.sh
```

## Optional validation

If you have the `skill-creator` tooling installed:

```bash
python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py \
  ~/git/verification_gated_coding/verification-gated-coding
```
