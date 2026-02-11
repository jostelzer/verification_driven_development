#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="verification-driven-development"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/${SKILL_NAME}"

MODE="symlink"   # symlink | copy
TARGET="auto"    # auto | agents | codex | claude | cursor | both | all
DRY_RUN="false"
CURSOR_PROJECT="$PWD"

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--mode symlink|copy] [--target auto|agents|codex|claude|cursor|both|all] [--cursor-project <path>] [--dry-run]

Options:
  --mode    Install mode. Default: symlink
  --target  Install location selection. Default: auto
            auto   -> prefer ~/.agents/skills if present, else ~/.codex/skills if present,
                      else ~/.claude/skills if present, else create ~/.agents/skills
            agents -> ~/.agents/skills
            codex  -> $CODEX_HOME/skills (or ~/.codex/skills)
            claude -> ~/.claude/skills
            cursor -> <cursor-project>/.cursor/rules/verification-driven-development.mdc
            both   -> install to ~/.agents/skills and ~/.codex/skills
            all    -> install to agents, codex, claude, and cursor rule
  --cursor-project  Cursor project root for --target cursor|all. Default: current working directory
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

is_safe_skill_dest() {
  case "$1" in
    */skills/"$SKILL_NAME") return 0 ;;
    *) return 1 ;;
  esac
}

is_safe_cursor_rule_dest() {
  case "$1" in
    */.cursor/rules/"$SKILL_NAME".mdc) return 0 ;;
    *) return 1 ;;
  esac
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
    --cursor-project)
      CURSOR_PROJECT="${2:-}"
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
CLAUDE_ROOT="$HOME/.claude/skills"
CURSOR_RULE_SRC="${SRC_DIR}/agents/cursor.mdc"
CURSOR_RULES_ROOT="${CURSOR_PROJECT}/.cursor/rules"
CURSOR_RULE_DEST="${CURSOR_RULES_ROOT}/${SKILL_NAME}.mdc"

declare -a SKILL_ROOTS=()
INSTALL_CURSOR="false"
case "$TARGET" in
  agents)
    SKILL_ROOTS+=("$AGENTS_ROOT")
    ;;
  codex)
    SKILL_ROOTS+=("$CODEX_ROOT")
    ;;
  claude)
    SKILL_ROOTS+=("$CLAUDE_ROOT")
    ;;
  cursor)
    INSTALL_CURSOR="true"
    ;;
  both)
    SKILL_ROOTS+=("$AGENTS_ROOT" "$CODEX_ROOT")
    ;;
  all)
    SKILL_ROOTS+=("$AGENTS_ROOT" "$CODEX_ROOT" "$CLAUDE_ROOT")
    INSTALL_CURSOR="true"
    ;;
  auto)
    if [[ -d "$AGENTS_ROOT" ]]; then
      SKILL_ROOTS+=("$AGENTS_ROOT")
    elif [[ -d "$CODEX_ROOT" ]]; then
      SKILL_ROOTS+=("$CODEX_ROOT")
    elif [[ -d "$CLAUDE_ROOT" ]]; then
      SKILL_ROOTS+=("$CLAUDE_ROOT")
    else
      SKILL_ROOTS+=("$AGENTS_ROOT")
    fi
    ;;
  *)
    echo "[error] invalid --target: $TARGET (expected auto, agents, codex, claude, cursor, both, or all)" >&2
    exit 1
    ;;
esac

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

if ((${#SKILL_ROOTS[@]} > 0)); then
  for ROOT in "${SKILL_ROOTS[@]}"; do
    DEST_DIR="${ROOT}/${SKILL_NAME}"

    run_cmd mkdir -p "$ROOT"

    if [[ -e "$DEST_DIR" || -L "$DEST_DIR" ]]; then
      if ! is_safe_skill_dest "$DEST_DIR"; then
        echo "[error] refusing to move unsafe destination path: $DEST_DIR" >&2
        exit 1
      fi
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
fi

if [[ "$INSTALL_CURSOR" == "true" ]]; then
  if [[ ! -f "$CURSOR_RULE_SRC" ]]; then
    echo "[error] cursor rule source not found: $CURSOR_RULE_SRC" >&2
    exit 1
  fi
  if ! is_safe_cursor_rule_dest "$CURSOR_RULE_DEST"; then
    echo "[error] refusing to use unsafe cursor rule path: $CURSOR_RULE_DEST" >&2
    exit 1
  fi

  run_cmd mkdir -p "$CURSOR_RULES_ROOT"
  if [[ -e "$CURSOR_RULE_DEST" || -L "$CURSOR_RULE_DEST" ]]; then
    CURSOR_BACKUP="${CURSOR_RULE_DEST}.bak.${TIMESTAMP}"
    run_cmd mv "$CURSOR_RULE_DEST" "$CURSOR_BACKUP"
    echo "[info] existing cursor rule moved to: $CURSOR_BACKUP"
  fi
  run_cmd cp "$CURSOR_RULE_SRC" "$CURSOR_RULE_DEST"
  echo "[ok] installed cursor rule to ${CURSOR_RULE_DEST}"
fi

echo "[next] restart your coding agent (or refresh skills/rules) to see changes"
