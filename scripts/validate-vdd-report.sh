#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CANONICAL_VALIDATOR="$REPO_ROOT/verification-driven-development/scripts/validate-vdd-report.sh"

if [ ! -f "$CANONICAL_VALIDATOR" ]; then
  echo "error: validator not found: $CANONICAL_VALIDATOR" >&2
  exit 1
fi

exec "$CANONICAL_VALIDATOR" "$@"
