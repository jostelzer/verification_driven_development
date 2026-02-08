#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="verification-gated-coding"
DEST_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
DEST_DIR="${DEST_ROOT}/${SKILL_NAME}"

if [[ -d "$DEST_DIR" ]]; then
  rm -rf "$DEST_DIR"
  echo "[ok] removed ${DEST_DIR}"
else
  echo "[info] skill not installed: ${DEST_DIR}"
fi
