#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  verification-driven-development/scripts/ensure-agent-ignore.sh [repo_root] [--mode auto|gitignore|info-exclude]

Description:
  Ensures `.agent` is ignored for the active repository.
  Default behavior prefers `.git/info/exclude` so verification scaffolding does
  not create tracked changes unless explicitly requested.
EOF
}

MODE="auto"
REPO_ARG=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [ -n "$REPO_ARG" ]; then
        echo "error: unexpected extra argument: $1" >&2
        usage >&2
        exit 2
      fi
      REPO_ARG="$1"
      shift
      ;;
  esac
done

case "$MODE" in
  auto|gitignore|info-exclude) ;;
  *)
    echo "error: --mode must be auto, gitignore, or info-exclude" >&2
    exit 2
    ;;
esac

REPO_ROOT="${REPO_ARG:-$PWD}"
if ! REPO_ROOT="$(git -C "$REPO_ROOT" rev-parse --show-toplevel 2>/dev/null)"; then
  echo "error: not inside a git repository: ${REPO_ARG:-$PWD}" >&2
  exit 1
fi

GITIGNORE="$REPO_ROOT/.gitignore"
INFO_EXCLUDE="$(git -C "$REPO_ROOT" rev-parse --git-path info/exclude)"
if [[ "$INFO_EXCLUDE" != /* ]]; then
  INFO_EXCLUDE="$REPO_ROOT/$INFO_EXCLUDE"
fi

has_agent_ignore() {
  local path="$1"
  [ -f "$path" ] && grep -Eq '^\.agent/?$' "$path"
}

append_ignore() {
  local path="$1"
  mkdir -p "$(dirname -- "$path")"
  touch "$path"
  printf '.agent\n' >> "$path"
}

if has_agent_ignore "$GITIGNORE"; then
  echo "already ignored via $GITIGNORE"
  exit 0
fi

if has_agent_ignore "$INFO_EXCLUDE"; then
  echo "already ignored via $INFO_EXCLUDE"
  exit 0
fi

case "$MODE" in
  gitignore)
    append_ignore "$GITIGNORE"
    echo "added .agent to $GITIGNORE"
    ;;
  auto|info-exclude)
    append_ignore "$INFO_EXCLUDE"
    echo "added .agent to $INFO_EXCLUDE"
    ;;
esac
