#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CANONICAL_RENDERER="$REPO_ROOT/verification-driven-development/scripts/render-vdd-failover-issue.sh"

if [ ! -f "$CANONICAL_RENDERER" ]; then
  echo "error: failover renderer not found: $CANONICAL_RENDERER" >&2
  exit 1
fi

exec "$CANONICAL_RENDERER" "$@"
