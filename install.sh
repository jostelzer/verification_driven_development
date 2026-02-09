#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="verification-gated-coding"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/${SKILL_NAME}"

MODE="symlink"   # symlink | copy
TARGET="auto"    # auto | agents | codex | both
DRY_RUN="false"

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--mode symlink|copy] [--target auto|agents|codex|both] [--dry-run]

Options:
  --mode    Install mode. Default: symlink
  --target  Install location selection. Default: auto
            auto   -> prefer ~/.agents/skills if present, else ~/.codex/skills if present,
                      else create ~/.agents/skills
            agents -> ~/.agents/skills
            codex  -> $CODEX_HOME/skills (or ~/.codex/skills)
            both   -> install to both locations
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
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
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

if [[ ! -d "$SRC_DIR" ]]; then
  echo "[error] skill source not found: $SRC_DIR" >&2
  exit 1
fi

if [[ "$MODE" != "symlink" && "$MODE" != "copy" ]]; then
  echo "[error] invalid --mode: $MODE (expected symlink or copy)" >&2
  exit 1
fi

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
  both)
    ROOTS+=("$AGENTS_ROOT" "$CODEX_ROOT")
    ;;
  auto)
    if [[ -d "$AGENTS_ROOT" ]]; then
      ROOTS+=("$AGENTS_ROOT")
    elif [[ -d "$CODEX_ROOT" ]]; then
      ROOTS+=("$CODEX_ROOT")
    else
      ROOTS+=("$AGENTS_ROOT")
    fi
    ;;
  *)
    echo "[error] invalid --target: $TARGET (expected auto, agents, codex, or both)" >&2
    exit 1
    ;;
esac

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

for ROOT in "${ROOTS[@]}"; do
  DEST_DIR="${ROOT}/${SKILL_NAME}"

  run_cmd mkdir -p "$ROOT"

  if [[ -e "$DEST_DIR" || -L "$DEST_DIR" ]]; then
    BACKUP_DIR="${DEST_DIR}.bak.${TIMESTAMP}"
    run_cmd mv "$DEST_DIR" "$BACKUP_DIR"
    echo "[info] existing skill moved to: $BACKUP_DIR"
  fi

  if [[ "$MODE" == "copy" ]]; then
    run_cmd cp -R "$SRC_DIR" "$DEST_DIR"
    echo "[ok] copied ${SKILL_NAME} to ${DEST_DIR}"
  else
    run_cmd ln -s "$SRC_DIR" "$DEST_DIR"
    echo "[ok] symlinked ${SKILL_NAME} to ${DEST_DIR}"
  fi
done

echo "[next] restart Codex app (or refresh skills) to see changes"
