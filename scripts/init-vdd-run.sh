#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CANONICAL_SCRIPT="$REPO_ROOT/verification-driven-development/scripts/init-vdd-run.sh"

if [ ! -f "$CANONICAL_SCRIPT" ]; then
  echo "error: init script not found: $CANONICAL_SCRIPT" >&2
  exit 1
fi

exec "$CANONICAL_SCRIPT" --repo-root "$REPO_ROOT" "$@"
