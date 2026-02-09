#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="verification-gated-coding"
TARGET="auto"    # auto | agents | codex | both
DRY_RUN="false"

usage() {
  cat <<'USAGE'
Usage: ./uninstall.sh [--target auto|agents|codex|both] [--dry-run]

Options:
  --target  Remove location selection. Default: auto
            auto   -> remove from both ~/.agents/skills and ~/.codex/skills
            agents -> ~/.agents/skills
            codex  -> $CODEX_HOME/skills (or ~/.codex/skills)
            both   -> remove from both
  --dry-run Print planned actions without changing files
  -h,--help Show this help
USAGE
}

run_cmd() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[error] unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

AGENTS_ROOT="$HOME/.agents/skills"
CODEX_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"

ROOTS=()
case "$TARGET" in
  agents)
    ROOTS+=("$AGENTS_ROOT")
    ;;
  codex)
    ROOTS+=("$CODEX_ROOT")
    ;;
  both|auto)
    ROOTS+=("$AGENTS_ROOT" "$CODEX_ROOT")
    ;;
  *)
    echo "[error] invalid --target: $TARGET (expected auto, agents, codex, or both)" >&2
    exit 1
    ;;
esac

for ROOT in "${ROOTS[@]}"; do
  DEST_DIR="${ROOT}/${SKILL_NAME}"
  if [[ -e "$DEST_DIR" || -L "$DEST_DIR" ]]; then
    run_cmd rm -rf "$DEST_DIR"
    echo "[ok] removed ${DEST_DIR}"
  else
    echo "[info] skill not installed at: ${DEST_DIR}"
  fi
done
