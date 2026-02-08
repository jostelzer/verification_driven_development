#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="verification-gated-coding"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/${SKILL_NAME}"
DEST_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
DEST_DIR="${DEST_ROOT}/${SKILL_NAME}"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "[error] skill source not found: $SRC_DIR" >&2
  exit 1
fi

mkdir -p "$DEST_ROOT"

if [[ -d "$DEST_DIR" ]]; then
  BACKUP_DIR="${DEST_DIR}.bak.$(date +%Y%m%d-%H%M%S)"
  mv "$DEST_DIR" "$BACKUP_DIR"
  echo "[info] existing skill moved to: $BACKUP_DIR"
fi

cp -R "$SRC_DIR" "$DEST_DIR"

echo "[ok] installed ${SKILL_NAME} to ${DEST_DIR}"
echo "[next] restart Codex app (or refresh skills) to see changes"
