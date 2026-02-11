#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="verification-driven-development"
TARGET="auto"    # auto | agents | codex | claude | cursor | both | all
DRY_RUN="false"
CURSOR_PROJECT="$PWD"

usage() {
  cat <<'USAGE'
Usage: ./uninstall.sh [--target auto|agents|codex|claude|cursor|both|all] [--cursor-project <path>] [--dry-run]

Options:
  --target  Remove location selection. Default: auto
            auto   -> remove from ~/.agents/skills, ~/.codex/skills, and ~/.claude/skills
            agents -> ~/.agents/skills
            codex  -> $CODEX_HOME/skills (or ~/.codex/skills)
            claude -> ~/.claude/skills
            cursor -> <cursor-project>/.cursor/rules/verification-driven-development.mdc
            both   -> remove from ~/.agents/skills and ~/.codex/skills
            all    -> remove from agents, codex, claude, and cursor rule
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

AGENTS_ROOT="$HOME/.agents/skills"
CODEX_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
CLAUDE_ROOT="$HOME/.claude/skills"
CURSOR_RULES_ROOT="${CURSOR_PROJECT}/.cursor/rules"
CURSOR_RULE_DEST="${CURSOR_RULES_ROOT}/${SKILL_NAME}.mdc"

declare -a ROOTS=()
REMOVE_CURSOR="false"
case "$TARGET" in
  agents)
    ROOTS+=("$AGENTS_ROOT")
    ;;
  codex)
    ROOTS+=("$CODEX_ROOT")
    ;;
  claude)
    ROOTS+=("$CLAUDE_ROOT")
    ;;
  cursor)
    REMOVE_CURSOR="true"
    ;;
  both)
    ROOTS+=("$AGENTS_ROOT" "$CODEX_ROOT")
    ;;
  auto)
    ROOTS+=("$AGENTS_ROOT" "$CODEX_ROOT" "$CLAUDE_ROOT")
    ;;
  all)
    ROOTS+=("$AGENTS_ROOT" "$CODEX_ROOT" "$CLAUDE_ROOT")
    REMOVE_CURSOR="true"
    ;;
  *)
    echo "[error] invalid --target: $TARGET (expected auto, agents, codex, claude, cursor, both, or all)" >&2
    exit 1
    ;;
esac

if ((${#ROOTS[@]} > 0)); then
  for ROOT in "${ROOTS[@]}"; do
    DEST_DIR="${ROOT}/${SKILL_NAME}"
    if [[ -e "$DEST_DIR" || -L "$DEST_DIR" ]]; then
      if ! is_safe_skill_dest "$DEST_DIR"; then
        echo "[error] refusing to remove unsafe destination path: $DEST_DIR" >&2
        exit 1
      fi
      run_cmd rm -rf "$DEST_DIR"
      echo "[ok] removed ${DEST_DIR}"
    else
      echo "[info] skill not installed at: ${DEST_DIR}"
    fi
  done
fi

if [[ "$REMOVE_CURSOR" == "true" ]]; then
  if ! is_safe_cursor_rule_dest "$CURSOR_RULE_DEST"; then
    echo "[error] refusing to remove unsafe cursor rule path: $CURSOR_RULE_DEST" >&2
    exit 1
  fi
  if [[ -e "$CURSOR_RULE_DEST" || -L "$CURSOR_RULE_DEST" ]]; then
    run_cmd rm -f "$CURSOR_RULE_DEST"
    echo "[ok] removed ${CURSOR_RULE_DEST}"
  else
    echo "[info] cursor rule not installed at: ${CURSOR_RULE_DEST}"
  fi
fi
